require 'socket'
::Chef::Recipe.send(:include, CycleCloud::Mounts::Helpers)


define :nfs_mount, :data => "" do
  name = params[:name]
  mount = params[:data]

  Chef::Log.info "Mounting nfs filesystem #{name} at #{mount['mountpoint']}"

  defaults = node['cshared']['client']['nfs']['defaults']
  mount = apply_defaults(name, mount, defaults)
  node.default['cyclecloud']['mounts'][name] = mount
  Chef::Log.debug "Setting #{name} attrs to #{mount.inspect}"

  server_ip = search_for_filer(node, name)

  mountpoint = mount['mountpoint']
  export_path = mount['export_path'] ||  mountpoint

  # If we're both exporting and mounting, don't try to mount our own exports
  # TODO: Find a more reliable way to identify local exports
  if Socket.ip_address_list.map { |addrinfo| addrinfo.ip_address }.include?(server_ip)
    Chef::Log.info "Skipping local export: #{name}"

    # We still need to ensure that the mountpoint path exists though...
    if export_path != mountpoint and not mountpoint.nil?
      base_path = ::File.dirname(mountpoint)
      directory base_path do
        not_if { ::File.exist?(base_path) }
      end

      link mountpoint do
        to export_path
        not_if { ::File.exist?(mountpoint) }
      end
    end

  else

    Chef::Log.info "Mounting NFS filesystem: #{name} at #{server_ip}:#{export_path} with attrs: #{mount.inspect}"

    if node[:platform] == "windows"

      drive_letter = mount['windevice']
      if not drive_letter.nil?
        drive_letter += ":" unless drive_letter.end_with?(':')
        Chef::Log.info "Mapping drive #{name} at #{drive_letter}..."

        mount drive_letter do
          device "\\\\#{server_ip}\\#{name}"
          not_if { ::File.exist?("#{drive_letter}\\") }
          retries 5
          retry_delay 30
        end
      end

    else
      include_recipe "nfs"

      # Create mount point (defaults to same path as the export on the server)
      # TODO: should probably make owner/perms configurable
      Chef::Log.info "Mounting #{name} filesystem at #{mountpoint}..."
      directory mountpoint  do
        owner "root"
        group "root"
        mode 0755 
        recursive true
        not_if "test -d #{mountpoint}"
      end

      mount mountpoint do
        device "#{server_ip}:#{export_path}"
        fstype mount['type']
        pass mount['pass']
        options mount['options']
        action [:mount, :enable]
        retries 5
        retry_delay 30
      end
    end
  end
end
