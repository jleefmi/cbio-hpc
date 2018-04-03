# Lustre mount defaults

default['cshared']['client']['lustre']['defaults']['type'] = nil  # 'fs_type' and 'type' are both accepted
default['cshared']['client']['lustre']['defaults']['disabled'] = false
default['cshared']['client']['lustre']['defaults']['export_path'] = nil
default['cshared']['client']['lustre']['defaults']['mountpoint'] = nil  # defaults to /mnt/shared/#{fs_name}
default['cshared']['client']['lustre']['defaults']['windevice'] = nil
default['cshared']['client']['lustre']['defaults']['cluster_name'] = nil
default['cshared']['client']['lustre']['defaults']['address'] = nil
default['cshared']['client']['lustre']['defaults']['pass'] = 0
default['cshared']['client']['lustre']['defaults']['options'] = ""
default['cshared']['client']['lustre']['defaults']['fsname'] = nil  # The lustre filesystem name to mount
