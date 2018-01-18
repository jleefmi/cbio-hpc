#
# Cookbook Name:: createusers
# Recipe:: chown_mounts.rb
#
# Copyright 2017, Cycle Computing, LLC
#
# All rights reserved - Do Not Redistribute
#


node['cyclecloud']['mounts'].each do |name, mount|
  mountpoint = mount['mountpoint']
  owner = mount['owner'].nil? ? "root" :  mount['owner']
  group = mount['group'].nil? ? owner :  mount['group']
  perms = mount['permissions'].nil? ? "0755" :  mount['permissions']
  
  Chef::Log.info "Setting ownership of #{name} filesystem to #{owner}:#{group} with perms: #{perms}..."
  directory mountpoint  do
    owner owner
    group group
    mode perms
    only_if "test -d #{mountpoint}"
  end
end
