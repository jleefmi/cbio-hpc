#
# Cookbook Name:: cshared
# Recipe:: directories
#
# Copyright 2010, Cycle Computing, LLC
#
# All rights reserved - Do Not Redistribute
#
# Creates standard shared directories on the file server
#

export_dir  = node[:cshared][:server][:export_dir]
shared_dir  = node[:cshared][:server][:shared_dir]
sched_dir   = node[:cshared][:server][:sched_dir]
shared_dirs = %w{home bin man scratch}

[export_dir, shared_dir, sched_dir].each do |dir|
  directory dir do
    owner "root"
    group "root"
    mode "0755"
  end
end

for dir in shared_dirs do

  m = "0755"
  if dir == "scratch"
    m = "0777"
  end 
  
  directory File.join(shared_dir, dir) do
    owner "root"
    group "root"
    mode m
  end

end

unless node['cshared']['server']['legacy_links_disabled'] == true  
  link "/shared" do
    to shared_dir
  end

  link "/sched" do
    to sched_dir
  end
end

