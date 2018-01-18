#
# Cookbook Name:: uge
# Recipe:: sgeexec
#

include_recipe "thunderball"
include_recipe "uge::sgefs"
include_recipe "uge::submitter"

sgeroot = node[:gridengine][:root]

# nodename assignments in the resouce blocks in this recipe are delayed till
# the execute phase by using the lazy evaluation.
# This accomodates run lists that change the hostname of the node.

myplatform=node[:platform]

package 'Install binutils' do
  package_name 'binutils'
end

package 'Install hwloc' do
  package_name 'hwloc'
end

case myplatform
when 'ubuntu'
  package 'Install libnuma' do
    package_name 'libnuma-dev'
#  when 'centos'
#    package_name 'whatevercentoscallsit'
  end
end

sgemake = node[:gridengine][:make]     # ge, sge
sgever = node[:gridengine][:version]   # 8.2.0-demo (ge), 8.2.1 (ge), 6_2u6 (sge), 2011.11 (sge, 8.1.8 (sge)
sgeroot = node[:gridengine][:root]     # /sched/ge/ge-8.2.0-demo

# HACK single spec creates a dictionary, multiple specs result in an array
if node[:cyclecloud][:specs].is_a?(Array)
  specs = node[:cyclecloud][:specs].select { |spec| spec['project'] == "uge" }
  installer_location = specs[0][:location]
else
  installer_location = node[:cyclecloud][:specs][:location]
end
  




shared_bin = node[:gridengine][:shared][:bin]

sgebins = {
  'ge'  => %w[bin-lx-amd64 bin-ulx-amd64 common],
  'sge' => %w[64 common]
}


if not(shared_bin)
  sgebins[sgemake].each do |arch|
     thunderball "#{sgemake}-#{arch}" do
       url "#{installer_location}/ge/#{sgemake}-#{sgever}-#{arch}.tar.gz"
       dest_file "#{node[:thunderball][:storedir]}/#{sgemake}-#{sgever}-#{arch}.tar.gz"
     end
  end

  # directory "#{node[:thunderball][:storedir]}" do
  #   owner 'root'
  #   group 'root'
  #   mode '0755'
  #   action :create
  # end
  #
  # sgebins[sgemake].each do |arch|
  #   cookbook_file "#{node[:thunderball][:storedir]}/#{sgemake}-#{sgever}-#{arch}.tar.gz" do
  #     source "installers/#{sgemake}-#{sgever}-#{arch}.tar.gz"
  #   end
  # end

  execute "untarcommon" do
    command "tar -xf #{node[:thunderball][:storedir]}/#{sgemake}-#{sgever}-common.tgz -C #{sgeroot}"
    creates "#{sgeroot}/inst_sge"
    action :run
  end

  sgebins[sgemake][0..-2].each do |myarch|

    execute "untar #{sgemake}-#{sgever}-#{myarch}.tgz" do
      command "tar -xf  #{node[:thunderball][:storedir]}/#{sgemake}-#{sgever}-#{myarch}.tgz -C #{sgeroot}"
      case sgemake
      when "ge"
        strip_bin = myarch.slice!(4..-1)
        creates "#{sgeroot}/bin/#{strip_bin}"
      when "sge"
        strip_bin = myarch.slice!(-3..-1)
        case strip_bin
        when "64"
          creates "#{sgeroot}/bin/linux-x64"
        when "32"
          creates "#{sgeroot}/bin/linux-x86"
        end
      end
      action :run
    end

  end
end

cookbook_file "#{node[:cyclecloud][:bootstrap]}/checkforjobs.sh" do
  source "checkforjobs.sh"
  owner "root"
  group "root"
  mode "0755"
  action :create
end

myplatform=node[:platform]
myplatform = "centos" if node[:platform_family] == "rhel" # TODO: fix this hack for redhat

# To keep everything consistent, SGE cleanup script uses the same hostname as the
# rest of the recipe. It used to shell out to `hostname`
template "/etc/init.d/sgeclean" do
  source "sgeclean.#{myplatform}.erb"
  owner "root"
  group "root"
  mode "0755"
  variables lazy {
    {
      :sgeroot => sgeroot,
      :nodename => node[:hostname]
    }
  }
end

template "/etc/init.d/sgeexecd" do
  source "sgeexecd.erb"
  mode 0755
  owner "root"
  group "root"
  variables({
    :sgeroot => sgeroot
  })
end

directory "/etc/acpi/events" do
  recursive true
end
cookbook_file "/etc/acpi/events/preempted" do
  source "preempted"
  mode "0644"
end

cookbook_file "/etc/acpi/preempted.sh" do
  source "preempted.sh"
  mode "0755"
end

sge_settings = "/etc/cluster-setup.sh"

slot_type = node[:gridengine][:slot_type] || "execute"
affinity_group = node[:cyclecloud][:node][:group_id] || "default"
affinity_group_cores = node[:cyclecloud][:node][:group_core_count] || nil

# TODO: Find a better way to detect execute node installation
# (needs to handle reuse of hostnames since sgeroot is shared)
service 'sgeexecd' do
  action [:enable, :start]
  only_if { ::File.exist?('/etc/sgeexecd.installed') }
  not_if { pidfile_running? ::File.join(sgeroot, 'default', 'spool', node[:hostname], 'execd.pid') }
end

execute "configure_slot_attributes" do
  set_slot_type = lambda { "qconf -mattr exechost complex_values slot_type=#{slot_type} #{node[:hostname]}" }
  set_affinity_group = lambda { "qconf -mattr exechost complex_values affinity_group=#{affinity_group} #{node[:hostname]}" }
  set_node_exclusivity = lambda { "qconf -mattr exechost complex_values exclusive=true #{node[:hostname]}" }
  set_slot_count = lambda { "true" }  # No-Op
  if node[:gridengine][:slots]
    set_slot_count = lambda { "qconf -mattr queue slots #{node[:gridengine][:slots]} all.q@#{node[:hostname]}" }
  end
  set_affinity_group_cores = lambda { "true" } # No-op
  if affinity_group_cores
    set_affinity_group_cores = lambda { "qconf -mattr exechost complex_values affinity_group_cores=#{affinity_group_cores} #{node[:hostname]}" }
  end

  command lazy {
    <<-EOS
      . #{sge_settings} && \
      #{set_slot_type.call} && \
      #{set_affinity_group.call} && \
      #{set_affinity_group_cores.call} && \
      #{set_node_exclusivity.call} && \
      #{set_slot_count.call}
    EOS

  }
  action :nothing
  notifies :start, 'service[sgeexecd]', :immediately
end

# Store node conf file to local disk to avoid requiring shared filesystem
template "#{Chef::Config['file_cache_path']}/compnode.conf" do
  source "compnode.conf.erb"
  variables lazy {
    {
      :sgeroot => sgeroot,
      :nodename => node[:hostname]
    }
  }
end

execute "install_sge_execd" do
  cwd sgeroot
  command "./inst_sge -x -noremote -auto #{Chef::Config['file_cache_path']}/compnode.conf && touch /etc/sgeexecd.installed"
  creates "/etc/sgeexecd.installed"
  notifies :run, 'execute[configure_slot_attributes]', :immediately
  action :nothing
end

defer_block 'Defer install and start of SGE execd until end of converge and Master authorizes node' do
  ruby_block "sge exec authorized?" do
    block do
      raise "SGE Execute node not authorized yet" unless ::File.exist? "#{sgeroot}/host_tokens/hasauth/#{node[:hostname]}"
    end
    retries 5
    retry_delay 30
    notifies :run, 'execute[install_sge_execd]', :immediately
  end
end

case myplatform
when "ubuntu"
  true # Ubuntu chokes on the chkconfig thing and I think the service enable should take care of it.
when "suse"
  true # Suse seems to work fine with the service as well
when "centos"
  execute "addcallback" do
    command "test -f /etc/init.d/sgeclean && /sbin/chkconfig --add sgeclean"
    creates "/etc/rc.d/rc0.d/K01sgeclean"
  end
end

service "sgeclean" do
  action [:enable, :start]
end

include_recipe "uge::autostop"
