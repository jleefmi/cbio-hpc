#!/bin/bash
# chgrp and chmod the built-in /srv directory to be writable by compbio group
# required for ChainLink installation

chgrp compbio /srv
chmod 775 /srv

