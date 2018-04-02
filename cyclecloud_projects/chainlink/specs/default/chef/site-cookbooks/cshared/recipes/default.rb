#
# Cookbook Name:: cshared
# Recipe:: default
#
# Copyright 2015, Cycle Computing
#
# All rights reserved - Do Not Redistribute
#

require 'socket'
::Chef::Recipe.send(:include, CycleCloud::Mounts::Helpers)

if node['cyclecloud']['mounts']
  # Configure NFS mounts
  node['cyclecloud']['mounts'].each do |name, mount|
    if disabled?(mount)
      Chef::Log.info("Skipping disabled filesystem: #{name}")
    elsif mount['type'] == 'lustre'
      lustre_mount name do
        data mount
      end
    elsif mount['type'] == 'efs'
      efs_mount name do
        data mount
      end
    elsif nfs_mount?(mount)
      nfs_mount name do
        data mount
      end
    else
      Chef::Log.info("Unknown filestystem '#{mount['type']}' for #{name} - skipping")
    end
  end
end
