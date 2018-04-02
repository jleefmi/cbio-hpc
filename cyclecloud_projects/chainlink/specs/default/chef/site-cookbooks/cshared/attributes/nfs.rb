# NFS mount defaults

default['cshared']['client']['nfs']['defaults']['type'] = nil
default['cshared']['client']['nfs']['defaults']['disabled'] = false
default['cshared']['client']['nfs']['defaults']['export_path'] = nil
default['cshared']['client']['nfs']['defaults']['mountpoint'] = nil  # defaults to /mnt/shared/#{fs_name}
default['cshared']['client']['nfs']['defaults']['windevice'] = nil
default['cshared']['client']['nfs']['defaults']['cluster_name'] = nil
default['cshared']['client']['nfs']['defaults']['address'] = nil
default['cshared']['client']['nfs']['defaults']['pass'] = 0
default['cshared']['client']['nfs']['defaults']['options'] = "defaults,proto=tcp,nfsvers=3,rsize=65536,wsize=65536,noatime"
