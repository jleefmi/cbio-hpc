#!/bin/bash
# This script will fail until the host has been authorized by SGE. Once that's
# done, it should delete the cron job.

. /etc/cluster-setup.sh

EXEC_MEMRES="127733344256"

case "$(curl -s http://169.254.169.254/latest/meta-data/instance-type)" in
    "r4.2xlarge")
    EXEC_MEMRES="63866672128"
    ;;
    "r4.4xlarge")
    EXEC_MEMRES="127733344256"
    ;;
    "r4.8xlarge")
    EXEC_MEMRES="255466688512"
    ;;
    "r4.16xlarge")
    EXEC_MEMRES="510933377024"
    ;;
esac

qconf -mattr exechost complex_values mem_reservation=${EXEC_MEMRES} "$(/bin/hostname)"

if [ $? -eq 0 ]; then
  rm /etc/cron.d/memrescron
fi
