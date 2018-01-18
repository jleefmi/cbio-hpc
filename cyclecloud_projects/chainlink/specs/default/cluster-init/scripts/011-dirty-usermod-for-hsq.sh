#!/bin/bash

# Dirty fix to allow pipeline_qa user to read BCL files from 150 ISILON

groupadd -g 1800 bcl1;
groupadd -g 1000000 bcl2;
groupadd -g 1000491 bcl3;
usermod -a -G 1800,1000000,1000491 pipeline_qa;
