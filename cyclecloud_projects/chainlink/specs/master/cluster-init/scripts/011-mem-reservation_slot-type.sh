#!/bin/bash
 
source /etc/cluster-setup.sh
 
set -e
set -x
 
cat <<EOF > /opt/cycle/jetpack/config/autoscale.py
#!/usr/env python
#
# File: /opt/cycle/jetpack/config/autoscale.py
#
def sge_job_handler(job):
    # The 'job' parameter is a dictionary containing the data present in a 'qstat -j <jobID>':
 
    # Return a dictionary containing the new job_slot requirement to be updated.
    details = {'slot_type' : 'execute',
               'affinity_group' : 'default'
    }
 
 
    # Dont' modify anything if the job already has a slot type
    # If the job has a mem_res, assume it needs high_mem for now (later check size
    if 'hard_resources' in job and 'mem_reservation' in job['hard_resources']:
        details['slot_type'] = 'highmem'
    elif 'hard_resources' in job and 'slot_type' in job['hard_resources']:
        details['slot_type'] = job['hard_resources']['slot_type']
    else:
        details['slot_type'] ='execute'
 
    return details
EOF
