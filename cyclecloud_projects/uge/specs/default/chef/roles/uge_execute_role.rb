name "uge_execute_role"
description "uge Client Role"
run_list("recipe[cyclecloud]",
  "recipe[cshared::client]",
  "recipe[cuser]",
  "recipe[cluster_init]",
  "recipe[uge::execute]",
  "recipe[cycle_server::submit_once_workers]",
  "recipe[cganglia::client]")
