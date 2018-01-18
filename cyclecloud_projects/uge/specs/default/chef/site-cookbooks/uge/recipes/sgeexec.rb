#
# Cookbook Name:: uge
# Recipe:: sgeexec
#

Chef::Log.warn("This recipe has been decprecated. Please use uge::execute instead")
include_recipe "uge::execute"
