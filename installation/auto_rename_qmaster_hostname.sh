#!/bin/bash
# Script to rename the qmaster from ip-<ip> to friendly hostname
# This hostname must already exist in MS DNS for this to work
# Note you have 30 minutes to add it before CycleCloud fails the deployment
# This script should ONLY run on Clusters tagged with a "GP" in the ClusterName
# JLouie 07AUG2018

set -e

# Log all stdout/err to a log file
exec >> /root/rename_qmaster_hostname.log
exec 2>&1

# Source for SGE_ROOT
source /etc/cluster-setup.sh

# AWS GetTag function
get_tag() {
 local region=$( query_metadata 'placement/availability-zone/' )
 local instance_id=$( query_metadata 'instance-id/' )

 aws --region ${region%?} ec2 describe-tags \
   --filters "Name=resource-id,Values=${instance_id}" \
   --query "Tags[?Key==\`${1}\`].Value" \
   --output text
}

query_metadata() {
 curl -s http://169.254.169.254/latest/meta-data/${1}
}

# Proceed if the Cycle ClusterName starts with GP, denoting Genomics Platform
if [ $(get_tag "ClusterName" | grep "^GP") ]; then
  NEW_FQDN=$(get_tag CL_FQDN | tr '[:upper:]' '[:lower:]');
  OLD_FQDN=$(hostname -f)

  # Wait for required CL_FQDN DNS entry to be created before proceeding
  while [[ $(host ${NEW_FQDN} | awk '{print $4}') != $(hostname -i | cut -d' ' -f1) ]]; do
    echo "$(date): ${NEW_FQDN} does not resolve to this hosts IP.  Will try again in 15 seconds..."
    sleep 15
  done

  # Add NEW_FQDN as UGE Admin and Submit host
  qconf -ah ${NEW_FQDN}
  qconf -as ${NEW_FQDN}

  # Rename UGE hostgroup with NEW_FQDN
  qconf -shgrp @allhosts > /tmp/ugeHosts.list
  sed -i "s/${OLD_FQDN}/${NEW_FQDN}/g" /tmp/ugeHosts.list
  qconf -Mhgrp /tmp/ugeHosts.list

  # Reconfigure UGE qmaster with NEW_FQDN
  /etc/init.d/sgeexecd stop
  /etc/init.d/sgemaster stop
  cp $SGE_ROOT/default/common/act_qmaster $SGE_ROOT/default/common/act_qmaster.bak
  echo "${NEW_FQDN}" > $SGE_ROOT/default/common/act_qmaster
  hostnamectl set-hostname --static ${NEW_FQDN}
  echo “preserve_hostname: true” >> /etc/cloud/cloud.cfg
  /etc/init.d/sgemaster start
  sleep 3
  /etc/init.d/sgeexecd start

  # Delete OLD_FQDN as UGE Admin and Submit host
  qconf -dh ${OLD_FQDN}
  qconf -ds ${OLD_FQDN}

  # Add manual entry for new FQDN to /etc/hosts
  sed -i "/localdomain6/a $(hostname -i) $(hostname -f) $(hostname -s)" /etc/hosts
fi
