#
# Cookbook Name:: uge
# Recipe:: master
#
# The SGE Master is a Q-Master and a Submitter
#

include_recipe "thunderball"

chefstate = node[:cyclecloud][:chefstate]

directory "#{node[:cyclecloud][:bootstrap]}/gridengine"

slot_type = node[:gridengine][:slot_type] || "master"

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
  end
when 'centos'
  package 'Install jemalloc' do
  package_name 'jemalloc'
  end
end


group node[:gridengine][:group][:name] do
  gid node[:gridengine][:group][:gid]
  not_if "getent group #{node[:gridengine][:group][:name]}"
end

user node[:gridengine][:user][:name] do
  comment node[:gridengine][:user][:description]
  uid node[:gridengine][:user][:uid]
  gid node[:gridengine][:user][:gid]
  home node[:gridengine][:user][:home]
  shell node[:gridengine][:user][:shell]
  not_if "getent passwd #{node[:gridengine][:user][:name]}"
end

directory "/sched/sge" do
  owner node[:gridengine][:user][:name]
  group node[:gridengine][:group][:name]
  mode "0755"
  action :create
  recursive true
  only_if "test -d /sched"
end

nodename = node[:cyclecloud][:instance][:hostname]
affinity_group = node[:cyclecloud][:node][:group_id] || 'default'

# HACK single spec creates a dictionary, multiple specs result in an array
if node[:cyclecloud][:specs].is_a?(Array)
  specs = node[:cyclecloud][:specs].select { |spec| spec['project'] == "uge" }
  installer_location = specs[0][:location]
else
  installer_location = node[:cyclecloud][:specs][:location]
end
  


sgemake = node[:gridengine][:make]     # ge, sge
sgever = node[:gridengine][:version]   # 8.2.0-demo (ge), 8.2.1 (ge), 6_2u6 (sge), 2011.11 (sge, 8.1.8 (sge)
sgeroot = node[:gridengine][:root]     # /sched/ge/ge-8.2.0-demo


sgebins = {
  'ge'  => %w[bin-lx-amd64 bin-ulx-amd64 common],
  'sge' => %w[64 common]
}

sgebins[sgemake].each do |arch|
   thunderball "#{sgemake}-#{arch}" do
     url "#{installer_location}/ge/#{sgemake}-#{sgever}-#{arch}.tar.gz"
     dest_file "#{node[:thunderball][:storedir]}/#{sgemake}-#{sgever}-#{arch}.tar.gz"
   end
end


#thunderball "ge-8.5.0-doc.tar.gz" do
#  url "ge/ge-8.5.0-doc.tar.gz"
#end


## ahoward: temporary workaround until thunderball can pull directly from the project
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

directory sgeroot do
  owner node[:gridengine][:user][:name]
  group node[:gridengine][:group][:name]
  mode "0755"
  action :create
  recursive true
end

execute "untarcommon" do
  command "tar -xf #{node[:thunderball][:storedir]}/#{sgemake}-#{sgever}-common.tar.gz -C #{sgeroot}"
  creates "#{sgeroot}/util"
  action :run
end

sgebins[sgemake][0..-2].each do |myarch|

  execute "untar #{sgemake}-#{sgever}-#{myarch}.tgz" do
    command "tar -xf  #{node[:thunderball][:storedir]}/#{sgemake}-#{sgever}-#{myarch}.tar.gz -C #{sgeroot}"
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

directory File.join(sgeroot, 'conf') do
  owner node[:gridengine][:user][:name]
  group node[:gridengine][:group][:name]
  mode "0755"
  action :create
  recursive true
end

%w( needauth hasauth needdelete hasdelete ).each do |dir|
  directory File.join(sgeroot, 'host_tokens', dir) do
    owner node[:gridengine][:user][:name]
    group node[:gridengine][:group][:name]
    mode "0755"
    action :create
    recursive true
  end
end

template "#{sgeroot}/conf/#{nodename}.conf" do
  source "headnode.conf.erb"
  variables(
    :sgeroot => sgeroot,
    :nodename => nodename,
    :ignore_fqdn => node[:gridengine][:ignore_fqdn]
  )
end

execute "installqmaster" do
  command "cd #{sgeroot} && ./inst_sge -m -auto ./conf/#{nodename}.conf"
  creates "#{sgeroot}/default"
  action :run
end

link "/etc/profile.d/sgesettings.sh" do
  to "#{sgeroot}/default/common/settings.sh"
end

link "/etc/profile.d/sgesettings.csh" do
  to "#{sgeroot}/default/common/settings.csh"
end

link "/etc/cluster-setup.sh" do
  to "#{sgeroot}/default/common/settings.sh"
end

link "/etc/cluster-setup.csh" do
  to "#{sgeroot}/default/common/settings.csh"
end

execute "set qmaster hostname" do
  command "hostname -f > #{sgeroot}/default/common/act_qmaster"
end

case node[:platform_family]
when "rhel", "suse"
  mail_root = "/bin"
when "debian"
  mail_root = "/usr/bin"
else
  throw "cluster_init: unsupported platform"
end

template "#{sgeroot}/conf/global" do
  source "global.erb"
  owner "root"
  group "root"
  mode "0755"
  variables(
    :sgeroot => sgeroot,
    :mail_root => mail_root
  )
end

template "#{sgeroot}/conf/sched" do
  source "sched.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "/etc/init.d/sgemaster" do
  source "sgemaster.erb"
  mode 0755
  owner "root"
  group "root"
  variables(
    :sgeroot => sgeroot
  )
end

service "sgemaster" do
  action [:enable, :start]
end

# Remove any hosts from previous runs
bash "clear old hosts" do
  code <<-EOH
  for HOST in `ls -1 #{sgeroot}/default/spool/ | grep -v qmaster`; do
    . /etc/cluster-setup.sh
    qmod -d *@${HOST}
    qconf -dattr hostgroup hostlist ${HOST} @allhosts
    qconf -de ${HOST}
    qconf -ds ${HOST}
    qconf -dh ${HOST}
    rm -rf #{sgeroot}/default/spool/${HOST};
  done && touch #{chefstate}/uge.clear.hosts
  EOH
  creates "#{chefstate}/uge.clear.hosts"
  action :run
end

template "/etc/init.d/sgeexecd" do
  source "sgeexecd.erb"
  mode 0755
  owner "root"
  group "root"
  variables(
    :sgeroot => sgeroot
  )
end

service 'sgeexecd' do
  action [:enable, :start]
  not_if { pidfile_running? ::File.join(sgeroot, 'default', 'spool', node[:hostname], 'execd.pid') }
end

execute "setglobal" do
  command ". /etc/cluster-setup.sh && qconf -Mconf #{sgeroot}/conf/global && touch #{chefstate}/uge.global.set"
  creates "#{chefstate}/uge.global.set"
  action :run
end

execute "setsched" do
  command ". /etc/cluster-setup.sh && qconf -Msconf #{sgeroot}/conf/sched && touch #{chefstate}/uge.sched.set"
  creates "#{chefstate}/uge.sched.set"
  action :run
end

template "#{node[:cyclecloud][:bootstrap]}/gridengine/sgemastercron.rb" do
  source "sgemastercron.rb.erb"
  mode 0755
  owner "root"
  group "root"
  variables(
    :sgeroot => sgeroot,
    :nodename => nodename,
    :slot_type => slot_type,
    :slots => node[:gridengine][:slots],
    :cyclecloudhome => node[:cyclecloud][:home]
  )
end

cron "addauth" do
  command "#{node[:cyclecloud][:bootstrap]}/cron_wrapper.sh #{node[:cyclecloud][:bootstrap]}/gridengine/sgemastercron.rb 2>&1 | logger -t 'sgemastercron'"
end

execute "showalljobs" do
  command "echo \"-u *\" > #{sgeroot}/default/common/sge_qstat"
  creates "#{sgeroot}/default/common/sge_qstat"
  action :run
end

execute "schedexecinst" do
  command "cd #{sgeroot} && ./inst_sge -x -noremote -auto #{sgeroot}/conf/#{nodename}.conf && touch #{chefstate}/uge.sgesched.schedexecinst"
  creates "#{chefstate}/uge.sgesched.schedexecinst"
  action :run
end

template "#{sgeroot}/conf/exec" do
  source "exec.erb"
  owner "root"
  group "root"
  mode "0755"
  variables(
    :nodename => nodename,
    :slot_type => slot_type,
    :affinity_group => affinity_group
  )
end

cookbook_file "#{sgeroot}/conf/complexes" do
  source "complexes"
  owner "root"
  group "root"
  mode "0755"
  action :create
end

template "#{sgeroot}/conf/mpislots" do
  source "mpislots.erb"
  owner "root"
  group "root"
  mode "0755"
end

# Install the SGE library functions we created
cookbook_file "#{node[:cyclecloud][:bootstrap]}/gridengine/sge.py" do
  source "sge.py"
end

cookbook_file "#{node[:cyclecloud][:bootstrap]}/gridengine/modify_jobs.py" do
  source "modify_jobs.py"
  owner "root"
  group "root"
  mode "0700"
  action :create
end

cron "modify jobs" do
  command "#{node[:cyclecloud][:bootstrap]}/cron_wrapper.sh #{node[:cyclecloud][:bootstrap]}/gridengine/modify_jobs.py >> #{node[:cyclecloud][:bootstrap]}/gridengine/modify_jobs.out 2>&1"
end

template "#{sgeroot}/conf/mpi" do
  source "mpi.erb"
  owner "root"
  group "root"
  mode "0755"
  variables(
    :sgeroot => sgeroot
  )
end

template "#{sgeroot}/conf/smpslots" do
  source "smpslots.erb"
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "#{sgeroot}/conf/pecfg" do
  source "pecfg"
  owner "root"
  group "root"
  mode "0755"
  action :create
end

template "#{sgeroot}/conf/uge.q" do
  source "uge.q.erb"
  owner "root"
  group "root"
  mode "0755"
  variables(
    :sgeroot => sgeroot
  )
end

cookbook_file "#{sgeroot}/SGESuspend.sh" do
  source "SGESuspend.sh"
  owner "root"
  group "root"
  mode "0755"
  only_if "test -d #{sgeroot}"
end

cookbook_file "#{sgeroot}/SGETerm.sh" do
  source "SGETerm.sh"
  owner "root"
  group "root"
  mode "0755"
  only_if "test -d #{sgeroot}"
end

execute "set complexes" do
  command ". /etc/cluster-setup.sh && qconf -Mc #{sgeroot}/conf/complexes && touch #{chefstate}/uge.setcomplexes.done"
  creates "#{chefstate}/uge.setcomplexes.done"
  action :run
end

%w( mpi mpislots smpslots ).each do |confFile|
  execute "Add the conf file: " + confFile do
    command ". /etc/cluster-setup.sh && qconf -Ap #{File.join(sgeroot, 'conf', confFile)}"
    not_if ". /etc/cluster-setup.sh && qconf -spl | grep #{confFile}"
  end
end

# Don't set the parallel environments for the all.q once we've already run this.
# To test, look for one of the PEs we add in the list of PEs associated with the queue.
execute "setpecfg" do
  command ". /etc/cluster-setup.sh && qconf -Rattr queue #{sgeroot}/conf/pecfg all.q"
  not_if ". /etc/cluster-setup.sh && qconf -sq all.q | grep mpislots"
end

# Configure the qmaster to not run jobs unless the jobs themselves are configured to run on the qmaster host.
# It shouldn't be a problem for this to be set every converge.
execute "setexec" do
  command ". /etc/cluster-setup.sh && qconf -Me #{sgeroot}/conf/exec"
end

#
execute "uge.qcfg" do
  command ". /etc/cluster-setup.sh && qconf -Rattr queue #{sgeroot}/conf/uge.q all.q && touch #{chefstate}/uge.qcfg"
  only_if "test -f #{sgeroot}/SGESuspend.sh && test -f #{sgeroot}/SGETerm.sh && test -f #{sgeroot}/conf/uge.q && test ! -f #{chefstate}/uge.qcfg"
end

execute "Add cycle_server user as a manager" do
  command ". /etc/cluster-setup.sh && qconf -am cycle_server"
  not_if ". /etc/cluster-setup.sh && qconf -sm | grep cycle_server"
end

# Modification for SGE-Autoscaling (autostop).
# SGE master logs qstat -t output every minute.
# Execute node looks to see if it's hostname is in the output (i.e: assigned to an SGE job)
# If so, node will not terminate.

directory "#{sgeroot}/activenodes/"

cron "Querying for active nodes" do
  command ". /etc/cluster-setup.sh && qstat -t 2> #{sgeroot}/activenodes/qstat_t.err 1> #{sgeroot}/activenodes/qstat_t.log"
end

# Pull in the Jetpack LWRP
include_recipe 'jetpack'

# Notify CycleCloud to configure GridEngine monitoring on each converge
applications = ''
if !node[:submitonce][:applications].nil? && !node[:submitonce][:applications].empty?
  if node[:submitonce][:applications].is_a?(Array)
    app_list = node[:submitonce][:applications].join(',')
  else
    app_list = node[:submitonce][:applications]
  end
  applications = "\"applications\": \"#{app_list}\""
end

monitoring_config = "#{node['cyclecloud']['home']}/config/service.d/gridengine.json"
file monitoring_config do
  content <<-EOH
  {
    "system": "gridengine",
    "cluster_name": "#{node[:cyclecloud][:cluster][:name]}",
    "hostname": "#{node[:cyclecloud][:instance][:public_hostname]}",
    "ports": {"ssh": 22},
    "cellname": "default",
    "sgeroot": "#{node[:gridengine][:root]}",
    "submitonce": {#{applications}}
  }
  EOH
  mode 750
  not_if { ::File.exist?(monitoring_config) }
end

jetpack_send "Registering QMaster for monitoring." do
  file monitoring_config
  routing_key "#{node[:cyclecloud][:service_status][:routing_key]}.gridengine"
end

include_recipe "uge::autostart"
