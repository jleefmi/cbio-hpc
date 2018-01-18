#!/usr/bin/env ruby
require 'json'

# Arguments
AUTOSTOP_ENABLED = `jetpack config cyclecloud.cluster.autoscale.stop_enabled`.downcase.strip == "true"
if not AUTOSTOP_ENABLED
  exit 0
end
  
IDLE_TIME_AFTER_JOBS = `jetpack config cyclecloud.cluster.autoscale.idle_time_after_jobs`.to_i
IDLE_TIME_BEFORE_JOBS = `jetpack config cyclecloud.cluster.autoscale.idle_time_before_jobs`.to_i
HOURLY_BILLING = `jetpack config cyclecloud.cluster.autoscale.hourly_billing`.downcase.strip == "true"
HOURLY_BILLING_WINDOW = `jetpack config cyclecloud.cluster.autoscale.hourly_billing_window`.to_i

# Checks to see if we should shutdown
idle_long_enough = false
in_billing_window = false


def IsActive()
   activejobs=system("ps -ef | grep sge_shepherd | grep -v grep > /dev/null 2>&1")
   activenode=system("grep \"$(hostname -s)[^0-9]\" $SGE_ROOT/activenodes/qstat_t.log > /dev/null 2>&1")
   if activejobs || activenode
     return true
   else
     return false
   end
end


# This is our autoscale runtime configuration
runtime_config = {
  "first_active_time" => nil,
  "idle_start_time" => nil
}
AUTOSCALE_DATA = "/opt/cycle/jetpack/run/autoscale.json"
if File.exist?(AUTOSCALE_DATA)
  file = File.read(AUTOSCALE_DATA)
  runtime_config.merge!(JSON.parse(file))
end

if IsActive()
  runtime_config["idle_start_time"] = nil
  if runtime_config["first_active_time"].nil?
    runtime_config["first_active_time"] = Time.now.to_i
  end
else
  if runtime_config["idle_start_time"].nil?
    runtime_config["idle_start_time"] = Time.now.to_i
  else
    idle_seconds = Time.now - Time.at(runtime_config["idle_start_time"].to_i)
    # DIfferent timeouts if the node has ever run a job
    if runtime_config["first_active_time"].nil?
      timeout = IDLE_TIME_BEFORE_JOBS
    else
      timeout = IDLE_TIME_AFTER_JOBS
    end
    
    if idle_seconds > timeout
      idle_long_enough = true
    end
    
    if HOURLY_BILLING
      launchtime = ::File.open('/opt/cycle/jetpack/config/startTime.txt').readline.strip.to_i
      
      seconds_difference = (Time.now.to_i - launchtime)
      if seconds_difference % 3600.0 >= 3600.0 - HOURLY_BILLING_WINDOW
        in_billing_window = true
      end
    end
  end
end

# Write the config information back for next time
file = File.new(AUTOSCALE_DATA, "w")
file.puts JSON.pretty_generate(runtime_config)
file.close

# Determine if we should shutdown the node
shutdown = false
if idle_long_enough
  shutdown = true
  if HOURLY_BILLING and not in_billing_window
    shutdown = false
  end
end

# Do the shutdown
if shutdown
  myhost=`hostname`
  system(". /etc/cluster-setup.sh;qmod -d *@#{myhost}")
  sleep(5)
  system("jetpack shutdown --idle")
end
