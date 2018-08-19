#!/bin/bash
# Script to add members of the compbio unix group as NOPASSWD sudoers
# In addition, adds the <pipeline_env> user as an UGE admin user
# This script only executes on hosts that are part of the Genomics Platform Unifcation
# Meaning it only applies to hosts part of ClusterNames that start with "GP"
# JLouie 06AUG2018

# Source for SGE_ROOT
source /etc/cluster-setup.sh

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

if [ $(get_tag "ClusterName" | grep "^GP") ]; then
  PIPELINE_USER=$(grep pipeline /etc/passwd | cut -d: -f1)
  echo "%compbio ALL=(${PIPELINE_USER}) NOPASSWD: ALL" > /etc/sudoers.d/compbio_group_sudoers;
  qconf -am ${PIPELINE_USER}
fi
