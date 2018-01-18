#!/bin/bash

source /etc/cluster-setup.sh

set -x
set -e

# Runs only on exec nodes
if ! test -d /etc/sge; then
    mkdir -p /etc/sge
fi

# Install temporary cron job to update mem_res info after node has been authorized by SGE
cp ${CYCLECLOUD_SPEC_PATH}/files/modify_mem_res.cron.sh /etc/sge
chmod +x /etc/sge/modify_mem_res.cron.sh 

cp ${CYCLECLOUD_SPEC_PATH}/files/memrescron /etc/cron.d/
chmod 644 /etc/cron.d/memrescron





 
