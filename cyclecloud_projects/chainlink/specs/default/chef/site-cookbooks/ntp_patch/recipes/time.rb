#
# Cookbook Name:: cyclecloud
# Recipe:: time
#
# Copyright 2016, Cycle Computing
#
# All rights reserved - Do Not Redistribute
#

# Instead of pulling in third-party ntp binaries on windows,
# we'll skip time configuration on this platform.
include_recipe 'ntp' unless node['os'] == 'windows'

if node['os'] == 'windows'
  Chef::Log.warn('Setting timezone in windows not yet supported')
else
  link '/etc/localtime' do
    to "/usr/share/zoneinfo/#{node['cyclecloud']['timezone']}"
  end
end

