# To modify the default /shared and /sched shares, set:
#
#      cyclecloud.exports.shared.*
#      cyclecloud.exports.sched.*
#
#      cyclecloud.mounts.shared.*
#      cyclecloud.mounts.sched.*
#
# Additional FS Client Mounts may be configured using:
#
#      cyclecloud.mounts.FS_NAME.*
#
# Additional FS Server Exports may be configured using
#
#      cyclecloud.exports.FS_NAME.*
#

# The cshared.server and cshared.client namespaces below are used ONLY to
# change default options
# => in general, cluster templates SHOULD NOT reference cshared.*

# Deprecated: Legacy client settings
default['cshared']['client']['fstype']    = nil
default['cshared']['client']['windevice']  = nil
default['cshared']['client']['clusterUID'] = nil
default['cshared']['client']['filer_ip']   = nil
default['cshared']['client']['pass']       = nil
default['cshared']['client']['mount_options'] = nil

# Deprecated: Legacy server settings
default['cshared']['server']['type'] = "nfs"
default['cshared']['server']['export_dir'] = "/mnt/exports"
default['cshared']['server']['shared_dir'] = "/mnt/exports/shared"
default['cshared']['server']['sched_dir']  = "/mnt/exports/sched"
default['cshared']['server']['samba']['log_level'] = "2"

# Default server settings (@see: https://github.com/atomic-penguin/cookbook-nfs )
default['cshared']['server']['defaults']['type'] = nil
default['cshared']['server']['defaults']['disabled'] = false
default['cshared']['server']['defaults']['export_path'] = nil
default['cshared']['server']['defaults']['owner'] = "root"
default['cshared']['server']['defaults']['group'] = "root"
default['cshared']['server']['defaults']['mode'] = "0777"
default['cshared']['server']['defaults']['network'] = '*'
default['cshared']['server']['defaults']['sync'] = true
default['cshared']['server']['defaults']['writable'] = true
default['cshared']['server']['defaults']['options'] = "no_root_squash"
default['cshared']['server']['defaults']['legacy_links_disabled'] = false
default['cshared']['server']['defaults']['samba']['enabled'] = false

# default /shared mount options (uses the default_nfs namespace so changes to other mounts don't remove /shared)
default['cshared']['client']['defaults']['shared']['type'] = "nfs"
default['cshared']['client']['defaults']['shared']['export_path'] = default['cshared']['server']['shared_dir']
default['cshared']['client']['defaults']['shared']['mountpoint'] = "/shared"
default['cshared']['client']['defaults']['shared']['windevice'] = "S"


# default /sched mount options (uses the default_nfs namespace so changes to other mounts don't remove /sched)
default['cshared']['client']['defaults']['sched']['type'] = "nfs"
default['cshared']['client']['defaults']['sched']['export_path'] = default['cshared']['server']['sched_dir']
default['cshared']['client']['defaults']['sched']['mountpoint'] = "/sched"
default['cshared']['client']['defaults']['sched']['windevice'] = nil  # Not mounted on windows

include_attribute 'nfs'
# This is a workaround for default selinux policies encountered on GCE CentOS 7 images.
case node['platform_family']
when 'rhel'
  if node['platform_version'] == '7.0.1406'
    override['nfs']['client-services'] = %w(rpcbind.service nfs-lock.service)
  elsif node['platform_version'] >= '7.1.1503'
    override['nfs']['client-services'] = %w(rpcbind.service nfs-lock.service nfs-client.target)
  end
end

# Configure 4 threads per core, dynamically
default['nfs']['threads'] = node['cpu']['total'] * 4
