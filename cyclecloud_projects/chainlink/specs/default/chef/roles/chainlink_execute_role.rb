name "chainlink_execute_role"
description "Chainlink Exec Role"
run_list("recipe[createusers]",
  "recipe[createusers::chown_mounts]",
  "recipe[fmihosts::change_hostname]",
  "recipe[cyclecloud]",
  "recipe[cshared::client]",
  "recipe[cuser]",
  "recipe[cluster_init]",
  "recipe[uge::execute]",
  "recipe[cycle_server::submit_once_workers]",
  "recipe[cganglia::client]")
