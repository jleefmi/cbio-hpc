::Chef::Recipe.send(:include, CycleCloud::Mounts::Helpers)

define :lustre_mount, :data => "" do
  name = params[:name]
  mount = params[:data]

  defaults = node['cshared']['client']['lustre']['defaults']
  mount = apply_defaults(name, mount, defaults)
  node.default['cyclecloud']['mounts'][name] = mount
  Chef::Log.debug "Setting #{name} attrs to #{mount.inspect}"

  include_recipe "lustre::client"

  server_ip = search_for_filer(node, name, "lustre::server")
  fsname = mount['fsname'] || name

  directory mount['mountpoint']  do
    owner "root"
    group "root"
    mode "0755"
    recursive true
  end

  mount mount['mountpoint'] do
    device "#{server_ip}:/#{fsname}"
    fstype mount['type']
    pass mount['pass']
    options mount['options']
    action [:mount, :enable]
    retries 5
    retry_delay 30
    # NOTE: We have a special guard here because without it
    # multiple entries are added to /etc/fstab on reconverge
    # This appears to be a chef bug in the mount resource (chef-solo 11.12.8)
    not_if "cat /etc/fstab | grep \"#{mount['mountpoint']}\""
  end
end
