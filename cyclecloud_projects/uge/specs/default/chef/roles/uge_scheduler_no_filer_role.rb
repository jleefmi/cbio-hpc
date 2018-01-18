name "uge_scheduler_no_filer_role"
description "uge Server (without filer) Role"
run_list("role[scheduler]",
    "recipe[cyclecloud]",
  "recipe[cshared::client]",
  "recipe[cuser]",
  "recipe[uge::master]",
  "recipe[cycle_server::submit_once_clients]",
  "recipe[cycle_server::submit_once_workers]",
  "recipe[cganglia::client]",
  "recipe[cluster_init]"")
