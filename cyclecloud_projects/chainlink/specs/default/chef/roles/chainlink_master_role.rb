name "chainlink_master_role"
description "Chainlink Master Role"
run_list("role[scheduler]",
  "recipe[createusers]",
  "recipe[createusers::chown_mounts]",
  "recipe[cyclecloud]",
  "recipe[cshared::directories]",
  "recipe[cuser]",
  "recipe[cshared::server]",
  "recipe[uge::master]",
  "recipe[cganglia::server]",
  "recipe[cluster_init]")

default_attributes "cyclecloud" => { "discoverable" => true }
