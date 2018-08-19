#
# Cookbook Name:: fmihosts
# Recipe:: set_instance_hostname.rb
#
#

if node['cyclecloud']['hosts']['simple_vpc_dns']['enabled']
  Chef::Log.info "Changing instance hostname to node['cyclecloud']['instance']['hostname']"
  domain = node['cyclecloud']['hosts']['standalone_dns']['suffix']

  new_hostname = node[:cyclecloud][:instance][:hostname]

  execute "hostname #{new_hostname}" do
    #= default[:cyclecloud][:instance][:hostname]
    only_if { node['hostname'] != new_hostname }
    command "hostname #{new_hostname}"
    notifies :reload, 'ohai[reload_hostname]', :immediately
  end
  ohai 'reload_hostname' do
    plugin 'hostname'
    action :nothing
  end


end

