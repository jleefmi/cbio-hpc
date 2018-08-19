#
# Cookbook Name:: fmihosts
# Recipe:: change_hostname.rb
#
#

if node['cyclecloud']['hosts']['standalone_dns']['enabled']
  domain = node['cyclecloud']['hosts']['standalone_dns']['suffix']
else
  domain = node['cyclecloud']['hosts']['simple_vpc_dns']['suffix']
end

Chef::Log.info "Updating Hosts file..."

# Modify self first
if not node['fmi']['hostname'].nil?
  Chef::Log.info "Renaming node to #{node['cyclecloud']['instance']['hostname']}"
  execute "Adding Local Hostname alias #{node['fmi']['hostname']} to /etc/hosts." do
    command "sed -i '/^\s*#{node['cyclecloud']['instance']['ipv4']} /c\ #{node['cyclecloud']['instance']['ipv4']} #{node['fmi']['hostname'] + "." + domain} #{node['fmi']['hostname']}' /etc/hosts"
  end

end



# Now add all the other searchable nodes
discoverable_nodes = cluster.search()
discoverable_nodes.each do |n|
    if not n['fmi']['hostname'].nil? && n['cyclecloud']['instance']['ipv4'] != node['cyclecloud']['instance']['ipv4']
      execute "Adding Hostname alias [ #{n['cyclecloud']['instance']['ipv4']} #{n['fmi']['hostname'] + "." + domain} #{n['fmi']['hostname']} ] to /etc/hosts." do
        command "sed -i '/^\s*#{n['cyclecloud']['instance']['ipv4']} /c\ #{n['cyclecloud']['instance']['ipv4']} #{n['fmi']['hostname'] + "." + domain} #{n['fmi']['hostname']}' /etc/hosts"
      end
      
    end
    
end
