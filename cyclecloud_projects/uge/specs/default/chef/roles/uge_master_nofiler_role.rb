name "uge_master_nofiler_role"
description "uge Master, but not the NFS server"
run_list("role[scheduler]",
  "recipe[cyclecloud]",
  "recipe[cshared::client]",
  "recipe[cuser]",
  "recipe[uge::master]",
  "recipe[cycle_server]",
  "recipe[cycle_server::xge_plugin]",
  "recipe[cycle_server::ganglia_plugin]",
  "recipe[cycle_server::chef_plugin]",
  "recipe[cycle_server::submit_once_plugin]",
  "recipe[cycle_server::file_sync_plugin]",
  "recipe[cganglia::server]",
  "recipe[cluster_init]")

default_attributes "cyclecloud" => { "discoverable" => true }
