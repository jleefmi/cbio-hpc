#
# Cookbook Name:: cshared
# Recipe:: client
#
# Copyright 2010, Cycle Computing, LLC
#
# All rights reserved - Do Not Redistribute
#
::Chef::Recipe.send(:include, CycleCloud::Mounts::Helpers)

# First set the defaults for the legacy) mounts if not set (CycleCloud tends to remove them)
if not node['cyclecloud'].key?('mounts')
  node.default['cyclecloud']['mounts'] = Mash.new
end

%w{ shared sched }.each do |name|
  # Skip disabled mounts
  next if disabled?(node['cyclecloud']['mounts'][name])

  if not node['cyclecloud']['mounts'].key?(name) or node['cyclecloud']['mounts'][name].nil?
    node.default['cyclecloud']['mounts'][name] = Mash.new(node['cshared']['client']['defaults'][name])
  end
  
  # If legacy `cshared.client.clusterUID` is set, translate it to the new format (if it's not already set)
  if not node['cshared']['client']['clusterUID'].nil? and node['cyclecloud']['mounts'][name]['cluster_name'].nil?
    node.default['cyclecloud']['mounts'][name]['cluster_name'] = node['cshared']['client']['clusterUID']
  end
  
  # Legacy `cshared.client.filer_ip` translation
  if not node['cshared']['client']['filer_ip'].nil? and node['cyclecloud']['mounts'][name]['address'].nil?
    node.default['cyclecloud']['mounts'][name]['address'] = node['cshared']['client']['filer_ip']
  end

  node.default['cyclecloud']['mounts'][name] = node['cshared']['client']['defaults'][name].merge(node['cyclecloud']['mounts'][name])

  # only /shared is mounted on windows
  if name == "shared" and node['cyclecloud']['mounts'][name]['windevice'].nil?
    node.default['cyclecloud']['mounts'][name]['windevice'] = node['cshared']['client']['windevice']
  end

  # Hack: We do the mount right here since this is kind of an attribute cookbook
  # cshared::default has likely already ran - this should actually be done with
  # attributes and NOT cshared::client
  nfs_mount name do
    data node['cyclecloud']['mounts'][name]
  end

  # Hack: SGE sometimes expands the /shared symlink on the master (when the
  # master is the nfs filer), so make sure the linked path exist on the client
  if node[:platform] != "windows"
    directory ::File.dirname(node['cyclecloud']['mounts'][name]['export_path'])
    link node['cyclecloud']['mounts'][name]['export_path'] do
      to node['cyclecloud']['mounts'][name]['mountpoint']
      not_if {::File.exist?(node['cyclecloud']['mounts'][name]['export_path'])}
    end
  end

end
