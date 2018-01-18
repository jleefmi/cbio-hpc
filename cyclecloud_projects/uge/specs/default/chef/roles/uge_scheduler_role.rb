# DEPRECATED:
# Use a single node with uge_master_role instead (or 2 nodes and a runlist
# that separates out the Monitor role and the uge Master role)
#
# This role is maintaine only for backwards compatibility with existing
# clusters.

name "uge_scheduler_role"
description "uge Server Role"
run_list("role[scheduler]",
  "recipe[cyclecloud]",
  "recipe[cshared::directories]",
  "recipe[cuser]",
  "recipe[cshared::server]",
  "recipe[uge::master]",
  "recipe[cycle_server::submit_once_clients]",
  "recipe[cycle_server::submit_once_workers]",
  "recipe[cganglia::client]",
  "recipe[cluster_init]")
