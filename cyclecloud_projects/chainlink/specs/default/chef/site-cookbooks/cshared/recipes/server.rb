#
# Cookbook Name:: cshared
# Recipe:: server
#
# Copyright 2010, Cycle Computing, LLC
#
# All rights reserved - Do Not Redistribute
#

#
# This recipe assumes that cshared::directories has already run and created
# the Legacy shared directories in the node[:cshared][:server][:shared_dir] and
# node[:cshared][:server][:sched_dir] attributes
#
include_recipe "jetpack"
include_recipe "nfs::server"
include_recipe "cshared::directories"
::Chef::Recipe.send(:include, CycleCloud::Mounts::Helpers)

unless node['cyclecloud'].key?('exports')
  node.default['cyclecloud']['exports'] = Mash.new
end

# Re-create default exports (they are removed if CycleCloud configures additional exports)
%w( shared sched ).each do |name|
  if !node['cyclecloud']['exports'].key?(name) || node['cyclecloud']['exports'][name].nil?
    node.default['cyclecloud']['exports'][name] = Mash.new
  end

  if node['cyclecloud']['exports'][name]['export_path'].nil?
    node.default['cyclecloud']['exports'][name]['export_path'] = node['cshared']['server']["#{name}_dir"]
  end
  if node['cyclecloud']['exports'][name]['type'].nil?
    node.default['cyclecloud']['exports'][name]['type'] = node['cshared']['server']['type']
  end
  if node['cyclecloud']['exports'][name]['mode'].nil?
    node.default['cyclecloud']['exports'][name]['mode'] = node['cshared']['server']['mode']
  end
end

# Legacy: Enable samba for shared by default
if node['cyclecloud']['exports']['shared']['samba'].nil?
  node.default['cyclecloud']['exports']['shared']['samba'] = Mash.new
end
if node['cyclecloud']['exports']['shared']['samba']['enabled'].nil?
  node.default['cyclecloud']['exports']['shared']['samba']['enabled'] = true
end


# Configure exports
samba_enabled = false
exported_paths = []
node['cyclecloud']['exports'].each do |name, export|
  # Skip FS marked as "disabled"
  Chef::Log.info("Processing export #{export.inspect}")
  if !nfs_mount?(export)
    Chef::Log.info("Skipping non-nfs export: #{name} with type: #{export['type']}")

    # Skip disabled FS mounts (allows disabling default exports)
  elsif disabled?(export)
    Chef::Log.info("Skipping disabled filesystem: #{name}")
  else
    if export['export_path'].nil?
      fail "Export #{name} has no export_path specified"
    end

    Chef::Log.info "Configuring the #{name} exports with attrs: #{export}"
    defaults = node['cshared']['server']['defaults']
    export = apply_defaults(name, export, defaults)
    node.default['cyclecloud']['exports'][name] = export
    Chef::Log.info "Setting export #{name} attrs to #{export.inspect}"

    samba_enabled |= (not export['samba'].nil? and not export['samba']['enabled'].nil? and 
                    export['samba']['enabled'])

    # Create the directory only if it wasn't created by a previous recipe (ex. cshared::directories)
    directory export['export_path'] do
      owner export['owner']
      group export['group']
      mode export['mode']
      recursive true
      not_if { ::File.exist?(export['export_path']) }
    end

    # Export options must be an array (but since mount options are comma-sep string, accept that too)
    export_options = export['options']
    unless export_options.is_a?(Array)
      # Assume comma-separated string
      export_options = export_options.split(',')
    end

    nfs_export export['export_path'] do
      network export['network']
      writeable export['writable']
      sync export['sync']
      options export_options
    end
    exported_paths << export['export_path']

  end
end

# Now mount additional mounts
include_recipe "cshared::client"

# Only start the Samba Service if at least one export enables samba
# TODO: For now, we ONLY support Samba exports for the default "shared"
# TODO: Later, we should enable samba per enabled export
if samba_enabled
  # TODO: Move Samba shares to a separate recipe, modern windows doesn't even
  # TODO: require Samba for NFS shares - it can simply mount NFS

  # configure samba exports -doesn't work on all platforms
  # We should probably conditionally include this instead of always configuring it
  case node[:platform]
  when "centos", "suse", "redhat", "ubuntu"
    include_recipe "samba::server"

    user     = node[:cyclecloud][:cluster][:user][:name]
    password = node[:cyclecloud][:cluster][:user][:password]

    ruby_block "add cluster user to samba" do
      block do
        File.open("#{node[:cyclecloud][:bootstrap]}/smbpasswd", "w") do |f|
          f.puts "#{password}\n#{password}"
        end

        system "cat #{node[:cyclecloud][:bootstrap]}/smbpasswd | smbpasswd -a #{user} -s"

        FileUtils.rm "#{node[:cyclecloud][:bootstrap]}/smbpasswd"
      end
      not_if "pdbedit -L | grep #{user} > /dev/null 2> /dev/null"
    end

    # NOTE: we used to export the /scratch dir but for consistency we should export the same directory as non-samba
    service_name = "smb"
    service_name = "smbd" if node[:platform] == "ubuntu"
    template "/etc/samba/smb.conf" do
      source "smb.conf.erb"
      owner "root"
      group "root"
      variables(:user => user, :shared_dir => node[:cshared][:server][:shared_dir])
      notifies :restart, "service[#{service_name}]", :immediately
    end

  end
else
  Chef::Log.info "Samba disabled."
end

# Notify CycleCloud that node exports NFS for auto-endpoint creation
# Shared filesystems should use "system=sharedfs" and differentiate using
# the "type=nfs" attribute
monitoring_config = "#{node['cyclecloud']['home']}/config/service.d/nfs.json"
file monitoring_config do
  content <<-EOH
  {
    "system": "sharedfs",
    "cluster_name": "#{node[:cyclecloud][:cluster][:name]}",
    "hostname": "#{node[:cyclecloud][:instance][:public_hostname]}",
    "ports": {"ssh": 22},
    "type": "nfs",
    "exports": "#{exported_paths.join(',')}"
  }
  EOH
  mode 750
  not_if { ::File.exist?(monitoring_config) }
end

jetpack_send "Registering NFS shared fs for monitoring." do
  file monitoring_config
  routing_key "#{node[:cyclecloud][:service_status][:routing_key]}.sharedfs"
end
