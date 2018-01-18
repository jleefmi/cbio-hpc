#
# Cookbook Name:: uge
# Recipe:: sgemaster
#
# The SGE Master is a Q-Master and a Submitter
#

Chef::Log.warn("This recipe has been decprecated. Please use uge::master instead")
include_recipe "uge::master"
