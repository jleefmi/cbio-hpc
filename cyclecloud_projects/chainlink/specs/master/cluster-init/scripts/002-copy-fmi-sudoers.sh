#!/bin/bash
# FMI script to copy all relevant sudoers file to allow members to su and sudo as needed

cp $CYCLECLOUD_SPEC_PATH/files/fmi-sudoers-* /etc/sudoers.d/
