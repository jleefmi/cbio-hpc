name "uge_master_role"
description "uge Master Role"
run_list("role[scheduler]",
  "recipe[cyclecloud]",
  "recipe[cshared::directories]",
  "recipe[cuser]",
  "recipe[cshared::server]",
  "recipe[uge::master]",
  "recipe[cycle_server]",
  "recipe[cycle_server::xge_plugin]",
  "recipe[cycle_server::ganglia_plugin]",
  "recipe[cycle_server::chef_plugin]",
  "recipe[cycle_server::submit_once_plugin]",
  "recipe[cycle_server::file_sync_plugin]",
  "recipe[cycle_server::dataman_plugin]",
  "recipe[cganglia::server]",
  "recipe[cluster_init]")

default_attributes "cyclecloud" => { "discoverable" => true }
