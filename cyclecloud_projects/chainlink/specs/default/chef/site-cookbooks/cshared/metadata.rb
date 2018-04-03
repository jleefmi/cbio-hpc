name             "cshared"
maintainer       "Cycle Computing, LLC"
maintainer_email "cyclecloud-support@cyclecomputing.com"
license          "All rights reserved"
description      "Installs/Configures shared filesystems"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"

depends          "nfs"
depends          "line"
depends          "samba"
depends          "lustre"
depends          "jetpack"
