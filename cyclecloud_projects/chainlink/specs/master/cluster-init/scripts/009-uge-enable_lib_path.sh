#!/bin/bash

source /etc/cluster-setup.sh

# Enable SUBMIT_LIB_PATH=TRUE on the qmaster
sed -i "/^qmaster_params/ s/$/ ENABLE_SUBMIT_LIB_PATH=TRUE/" $SGE_ROOT/conf/global
qconf -Mconf $SGE_ROOT/conf/global;
