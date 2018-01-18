# DEPRECATED:
# Use a single node with uge_master_role instead (or 2 nodes and a runlist
# that separates out the Monitor role and the uge Master role)
#
# This role is maintaine only for backwards compatibility with existing
# clusters.

name "uge_manager_role"
description "uge Manager Role"
run_list("recipe[cyclecloud]",
  "recipe[uge::master]",
  "recipe[cshared::client]",
  "recipe[cuser]",
  "recipe[cycle_server::4-2-x]",
  "recipe[cycle_server::xge_plugin]",
  "recipe[cycle_server::ganglia_plugin]",
  "recipe[cycle_server::chef_plugin]",
  "recipe[cycle_server::submit_once_plugin]",
  "recipe[cycle_server::file_sync_plugin]",
  "recipe[cycle_server::s3tools_plugin]",
  "recipe[cganglia::server]",
  "recipe[cluster_init]")
