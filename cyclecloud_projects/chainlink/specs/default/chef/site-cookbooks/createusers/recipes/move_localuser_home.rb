#
# Cookbook Name:: createusers
# Recipe:: move_localuser_home.rb
#
# Copyright 2017, Cycle Computing, LLC
#
# All rights reserved - Do Not Redistribute
#


# Move local users
directory "/local_home" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

%w{ cyclecloud centos sge }.each do | localuser |
  Chef::Log.info("Will move  #{localuser} home to  /local_home/#{localuser}")
  execute "Moving #{localuser} home" do
    command "usermod -m -d /local_home/#{localuser} #{localuser}"
    only_if "test -d /home/#{localuser}"
    not_if "test -d /local_home/#{localuser}"
  end
end




