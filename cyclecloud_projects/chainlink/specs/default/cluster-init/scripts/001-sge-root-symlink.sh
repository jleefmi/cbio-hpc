#!/bin/bash

set -e
set -x

source /etc/profile

echo "Linking SGE_ROOT to /opt"

rm -rf /opt/uge-8.5.0
ln -s ${SGE_ROOT} /opt/uge-8.5.0
