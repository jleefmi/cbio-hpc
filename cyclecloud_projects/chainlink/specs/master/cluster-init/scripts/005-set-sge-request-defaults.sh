#!/bin/bash

source /etc/cluster-setup.sh

set -e
set -x


cat <<EOF >> $SGE_ROOT/default/common/sge_request

-l slot_type=execute,affinity_group=default 

EOF
