#! /bin/bash

RPC_SLOTS=$( jetpack config fmi.sysctl.rpc_slots 2> /dev/null )

set -e

# This flag is set to decrease the TCP/RPC command window queue to match the Cloud Storage Avere
if [ -z "${RPC_SLOTS}" ];then
  RPC_SLOTS=128
fi 
printf "\nsunrpc.tcp_max_slot_table_entries=${RPC_SLOTS}\nsunrpc.tcp_slot_table_entries=${RPC_SLOTS}\n" > /etc/sysctl.d/99-fmi_avere.conf && sysctl --system;
