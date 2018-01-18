#!/bin/bash

source /etc/cluster-setup.sh

# Runs only on scheduler
qconf -sc > /tmp/memrescomplex
sed -i '/^#-----*/a mem_reservation     mem_res     MEMORY      <=    YES         JOB        7.24G    0       YES' /tmp/memrescomplex
qconf -Mc /tmp/memrescomplex




 
