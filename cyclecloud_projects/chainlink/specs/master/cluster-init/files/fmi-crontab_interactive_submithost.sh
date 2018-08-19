#!/bin/bash -x

### This is the cron.d file:
### echo "*/5 * * * * root /opt/interactiveNode/interactiveHost.sh" > /etc/cron.d/interactiveHost

exec 1>/var/log/fmi-interactiveHost.log 2>&1
## Check if Host comes back with an IP

## Note this is not prescriptive where this assumes there is only one Interactive host per environment
hostName=$(ls /sched/ge/ge-8.5.0/host_tokens/hasauth | grep INT)

if [ "$?" -ne 0 ]
then
  echo "No Interactive Host"
  exit 1
fi

newHostIP=$(host ${hostName} | awk '{print $4}')

if [ "$?" -ne 0 ]
then
  echo "Not a valid host name"
  exit 1
fi

oldHostIP=$(cat /etc/hosts | grep ${hostName} | cut -d" " -f1)

if [ "$?" -ne 0 ]
then
  echo "Interactive node found!"
fi

if [ "${oldHostIP}" = "" ]
then
  echo "No Old Hostname defined must be a new entry!"
  sed -i "/localdomain6/a ${newHostIP} ${hostName}" /etc/hosts
else
  if [ "${newHostIP}" = "${oldHostIP}" ]
  then
    echo "Submit host IP has not been updated"
    exit 1
  fi
  sed -i "s/${oldHostIP} ${hostName}/${newHostIP} ${hostName}/g" /etc/hosts
fi
