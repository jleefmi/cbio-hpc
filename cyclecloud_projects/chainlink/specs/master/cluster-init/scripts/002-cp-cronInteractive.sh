#!/bin/bash
# FMI script
# Copy the fmi-crontab_interactive_submithost.sh file from the local locker into /opt/interactiveNode/interactiveHost.sh
# echo the cron schedule and file path into /etc/cron.d
### echo "*/5 * * * * root /opt/interactiveNode/interactiveHost.sh" > /etc/cron.d/interactiveHost

mkdir -p /opt/interactiveNode
cp ${CYCLECLOUD_SPEC_PATH}/files/fmi-crontab_interactive_submithost.sh /opt/interactiveNode/
chmod +x /opt/interactiveNode/fmi-crontab_interactive_submithost.sh
echo "*/5 * * * * root /opt/interactiveNode/fmi-crontab_interactive_submithost.sh" > /etc/cron.d/interactiveHost
