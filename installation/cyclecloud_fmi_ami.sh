#!/bin/bash

export CS_VERSION=6.8.1
export CYCLECLOUD_LOCKER="fm-ae1-cyclecloud-poc"

# OS Packages and Updates
yum -y update
yum -y install epel-release
yum install -y python-pip java-1.8.0-openjdk.x86_64
pip install -U pip awscli

# CycleCloud Installs
mkdir /tmp/installers
cd /tmp/installers
aws s3 cp --recursive s3://${CYCLECLOUD_LOCKER}/installers/${CS_VERSION}/ .
tar xzf jetpack*tar.gz
tar xzf pogo*tar.gz
mv pogo /usr/local/bin/
cd jetpack*
chmod a+x ./install.sh
./install.sh --provider aws


## CompBio Installs
echo "alsa-libat
attr
augeas-libs
avahi-autoipd
avahi-libs
bash-completion
bc
bind-libs
bind-utils
biosdevname
blktrace
boost-system
boost-thread
bridge-utils
bzip2
c-ares
crda
cryptsetup
cups-libs
cyrus-sasl-gssapi
cyrus-sasl-plain
desktop-file-utils
device-mapper-event
device-mapper-event-libs
device-mapper-persistent-data
dmraid
dmraid-events
dosfstools
dyninst
ebtables
ed
elfutils
emacs-filesystem
firewalld
fontconfig
fontpackages-filesystem
fprintd
fprintd-pam
fxload
gcc
gcc-c++
gdb
gdk-pixbuf2
gpm-libs
hunspell
hunspell-en
hunspell-en-GB
hunspell-en-US
iprutils
iw
jasper-libs
kpatch
krb5-workstation
langtable
langtable-data
langtable-python
ledmon
libaio
libcgroup-tools
libconfig
libdhash
libdnet
libdrm
libdwarf
libfprint
libgfortran
libicu
libipa_hbac
libldb
libmspack
libnl
libpciaccess
libpng
libquadmath
libreport
libreport-cli
libreport-filesystem
libreport-plugin-mailx
libreport-plugin-rhtsupport
libreport-plugin-ureport
libreport-python
libreport-rhel
libreport-web
libseccomp
libsmbclient
libsss_idmap
libsss_nss_idmap
libstoragemgmt
libstoragemgmt-python
libtar
libtdb
libtool-ltdl
libusb
libusbx
libwbclient
libX11
libX11-common
libXau
libxcb
libXft
libXrender
libxslt
lm_sensors-libs
lsof
lsscsi
lvm2
lvm2-libs
m2crypto
mailx
man-pages
man-pages-overrides
mdadm
mlocate
mtr
nano
net-snmp
net-snmp-agent-libs
net-snmp-libs
ntpdate
ntsysv
oddjob
oddjob-mkhomedir
open-vm-tools
perl
perl-Carp
perl-constant
perl-Data-Dumper
perl-Encode
perl-Exporter
perl-File-Path
perl-File-Temp
perl-Filter
perl-Getopt-Long
perl-HTTP-Tiny
perl-libs
perl-macros
perl-parent
perl-PathTools
perl-Pod-Escapes
perl-podlators
perl-Pod-Perldoc
perl-Pod-Simple
perl-Pod-Usage
perl-Scalar-List-Utils
perl-Socket
perl-Storable
perl-Text-ParseWords
perl-threads
perl-threads-shared
perl-Time-HiRes
perl-Time-Local
pinfo
plymouth
plymouth-core-libs
plymouth-scripts
pm-utils
psacct
psmisc
pygobject2
pyOpenSSL
pytalloc
python-augeas
python-dateutil
python-dmidecode
python-ethtool
python-gudev
python-hwdata
python-lxml
python-magic
python-qpid-proton
python-slip
python-slip-dbus
python-sssdconfig
qemu-guest-agent
qpid-proton-c
rdate
realmd
rfkill
rng-tools
samba-client
samba-client-libs
samba-common
samba-common-libs
samba-common-tools
samba-libs
satyr
scl-utils
setserial
setuptool
sg3_utils-libs
sgpio
smartmontools
sos
sssd
sssd-ad
sssd-client
sssd-common
sssd-common-pac
sssd-ipa
sssd-krb6
sssd-krb5-common
sssd-ldap
sssd-proxy
strace
sysstat
systemd-python
systemtap-runtime
tcl
tcpdump
tcsh
time
tk
traceroute
unzip
usermode
vim-common
vim-enhanced
vim-filesystem
wget
words
xdg-utils
xfsdump
xmlrpc-c
xmlrpc-c-client
yajl
yum-langpacks
zip
ncurses-devel
zlib-devel
bzip2-devel
xz-devel
xorg-x11-xauth
xterm
libICE
libSM
libXaw
libXmu
libXpm
libXt
gedit
pygtk2" > /tmp/cbio_packages.txt

yum install -y $(cat /tmp/cbio_packages.txt)

## Disable firewalld
systemctl stop firewalld
sleep 5
systemctl disable firewalld
