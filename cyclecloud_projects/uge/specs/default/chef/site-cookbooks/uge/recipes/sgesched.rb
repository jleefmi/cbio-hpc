#
# Cookbook Name:: uge
# Recipe:: sgesched
#
#
# IMPORTANT:  DEPRECATED
#
# This recipe is a duplicate of master
# sgesched and sgecm are retained only for backwards compat. in older
# roles.

Chef::Log.warn("This recipe has been decprecated. Please use uge::master instead")
include_recipe "uge::master"
