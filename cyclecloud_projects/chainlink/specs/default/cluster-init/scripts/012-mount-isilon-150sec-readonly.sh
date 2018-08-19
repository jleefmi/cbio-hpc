#!/bin/bash
# Dirty read-only mount of existing Isilon directories as of 02AUG2018
# Also symlink /compbio/versions > /pipeline/versions if true

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

if [ $(get_tag "Mount Isilon") = "enabled" ]; then
  echo "fm-150sec-nas01-nfs02.corp.local:/ifs/data/compbio/data /compbio/data nfs ro,nfsvers=3,tcp,hard,intr,rsize=131072,wsize=524288 0 0" >> /etc/fstab;
  mkdir -p /compbio/data;
  mount /compbio/data;

  echo "fm-150sec-nas01-nfs02.corp.local:/ifs/data/compbio/specimens /compbio/specimens nfs ro,nfsvers=3,tcp,hard,intr,rsize=131072,wsize=524288 0 0" >> /etc/fstab;
  mkdir -p /compbio/specimens;
  mount /compbio/specimens;

  echo "fm-150sec-nas01-nfs02.corp.local:/ifs/data/compbio/analysis /compbio/analysis nfs ro,nfsvers=3,tcp,hard,intr,rsize=131072,wsize=524288 0 0" >> /etc/fstab;
  mkdir -p /compbio/analysis;
  mount /compbio/analysis;

  echo "fm-150sec-nas01-nfs02.corp.local:/ifs/data/compbio/development /compbio/development nfs rw,nfsvers=3,tcp,hard,intr,rsize=131072,wsize=524288 0 0" >> /etc/fstab;
  mkdir -p /compbio/development;
  mount /compbio/development;

  ln -s /pipeline/versions /compbio/versions;
  ln -s /pipeline/software /compbio/software;
  ln -s /pipeline/references /compbio/references;

fi

if [ $(get_tag "Environment" | tr '[:upper:]' '[:lower:]') = "development" ]; then
  echo "fm-150sec-nas01-nfs02.corp.local:/ifs/compbio_dev /compbio_env nfs ro,nfsvers=3,tcp,hard,intr,rsize=131072,wsize=524288 0 0" >> /etc/fstab;
  mkdir -p /compbio_env;
  mount /compbio_env;
fi

if [ $(get_tag "Environment" | tr '[:upper:]' '[:lower:]') = "qa" ]; then
  echo "fm-150sec-nas01-nfs02.corp.local:/ifs/compbio_qa /compbio_env nfs nfsvers=3,tcp,hard,intr,rsize=131072,wsize=524288 0 0" >> /etc/fstab;
  mkdir -p /compbio_env;
  mount /compbio_env;
fi
