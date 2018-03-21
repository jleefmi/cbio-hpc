<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->

**Table of Contents**

- [CycleCloud Overview:](#cyclecloud-overview)
- [Installing Cyclecloud:](#installing-cyclecloud)
    - [Basic Installation:](#basic-installation)
        - [Copy cyclecloud configuration files](#copy-cyclecloud-configuration-files)
        - [Set ports and HTTPS](#set-ports-and-https)
        - [Account and User Setup:](#account-and-user-setup)
    - [Cloud Formation:](#cloud-formation)
- [Image Building:](#image-building)
- [The Chainlink Cluster](#the-chainlink-cluster)
    - [Projects](#projects)
        - [Operations:](#operations)
        - [Common CLI Commands](#common-cli-commands)
        - [When is are Restarts Required?](#when-is-are-restarts-required)
        - [How can I apply Changes **WITHOUT** a Restart?](#how-can-i-apply-changes-without-a-restart)
            - [What if I need to apply a change to the UGE Master Node without Restart?](#what-if-i-need-to-apply-a-change-to-the-uge-master-node-without-restart)
        - [What if I need to Restart CycleCloud?](#what-if-i-need-to-restart-cyclecloud)
        - [What if the CycleCloud host is Terminated?](#what-if-the-cyclecloud-host-is-terminated)
    - [Cluster template vs Cluster-init](#cluster-template-vs-cluster-init)
        - [User Creation](#user-creation)
        - [FileSystem Mounts](#filesystem-mounts)
    - [The Chainlink Project](#the-chainlink-project)
        - [Other Customizations:](#other-customizations)
- [Trouble Shooting:](#trouble-shooting)

<!-- markdown-toc end -->


# CycleCloud Overview: #


Foundation Medicine uses CycleCloud to orchestrate Chainlink clusters for multiple teams in the US and (soon) China.  CycleCloud's role is to spin up the infrastructure, install UGE and Chainlink, mount Avere, auto-scale the worker nodes to fit the workload, and to monitor and alert on UGE and infrastructure issues.
CycleCloud Documentation:

The general CycleCloud documentation provides much more complete information about deploying, operating and extending CycleCloud: https://docs.cyclecomputing.com/
Here are a few relevant chapters (note that these links refer to CycleCloud 6.6 and there may be newer versions):

  1.	Installation : https://docs.cyclecomputing.com/installation-guide-launch
  2.	Image Building: https://docs.cyclecomputing.com/administrator-guide-v6.6.0/image_reference
  3.	CycleCloud Projects and Deployment: https://docs.cyclecomputing.com/administrator-guide-v6.6.0/projects


# Installing Cyclecloud: #

## CycleCloud Locker Creation ##

  1. Create a new bucket for use as the CycleCloud locker
     - Set bucket policy (encryption, etc.)
  2. Copy the Installers directory to the new bucket:
     - From : aws s3 cp --recursive s3://fm-ae1-cyclecloud-poc/installers/ /tmp/installers/
     - To: aws s3 cp --recursive /tmp/installers/ s3://${NEW_BUCKET_NAME}/installers/
  3. Create the CycleCloud IAM policy and role using the [installers/CycleCloud_IAM_Policy.json]


## CycleCloud Instance Role Creation ##

  1. Create a new IAM Policy and Role for the new cyclecloud instance
     a. Copy the role from the existing policy on-prem

**TODO** Add the sample policy file


## Basic Installation: ##

Launch a new instance with the following minimum specs:

  * CycleCloud Instance Role
  * 4 CPUs
  * 16 GB RAM
  * 100 GB SSD EBS storage for CycleCloud data


CycleCloud may be installed on the new instance manually using the following script:

``` bash

   #!/bin/bash

   set -x
   set -e

   export CS_HOME=/opt/cycle_server
   export CS_VERSION=6.6.0
   export INSTALL_DIR=/tmp/cyclecloud
   mkdir -p ${INSTALL_DIR}
   chmod a+rwX ${INSTALL_DIR}

   echo "Bootstrapping CycleCloud..."                                                                                                                                                                                                                                                                                                                                                                            
   echo "Fetching CycleCloud Bootstrap script..."

   yum -y update
   yum -y install epel-release
   yum install -y python-pip java-1.8.0-openjdk.x86_64

   pip install -U pip awscli pystache argparse python-daemon requests

   cd ${INSTALL_DIR}
   aws s3 cp --recursive s3://fm-ae1-cyclecloud-poc/installers/${CS_VERSION}/ .
   tar xzf cyclecloud*tar.gz
   tar xzf pogo*tar.gz
   tar xzf cycle_server-all*tar.gz
   mv cyclecloud /usr/local/bin/
   mv pogo /usr/local/bin/

   pushd cycle_server/
   ./install.sh --nostart
   popd


   ### Copy cyclecloud configuration files ###


   chown cycle_server:cycle_server ${INSTALL_DIR}/cyclecloud_init.txt
   chown cycle_server:cycle_server ${INSTALL_DIR}/users_init.txt
   cp ${INSTALL_DIR}/cyclecloud_init.txt ${CS_HOME}/config/data
   cp ${INSTALL_DIR}/users_init.txt ${CS_HOME}/config/data

   cd ${CS_HOME}
<<<<<<< HEAD
   
   ### Set ports and HTTPS ###

```
### Create Self Signed SSL Certificate ###

``` bash
echo "${cyn}Create self-signed SSL cert...${end}";
keytool -genkey \
-keyalg RSA \
-sigalg SHA256withRSA \
-alias CycleServer \
-dname "CN=Foundation Medicine, OU=IT, O=Foundation Medicine, L=Cambridge, ST=MA, C=US" \
-keypass "SelfSignedUseOnlyPlease" \
-keystore .keystore \
-storepass "SelfSignedUseOnlyPlease"

mv .keystore ${CS_HOME}/
chown cycle_server:cycle_server ${CS_HOME}/.keystore
```

### Set Cert, Ports and HTTPS ###
>>>>>>> 5c56ff5bab4ebe8157780b566f20efbcf36b17df

``` bash
sed -i 's/^webServerKeystorePass=changeit/webServerKeystorePass=SelfSignedUseOnlyPlease/' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerMaxHeapSize/c webServerMaxHeapSize=8192M' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerPort/c webServerPort=80' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerSslPort/c webServerSslPort=443' ${CS_HOME}/config/cycle_server.properties
sed -i '/^brokerMaxHeapSize/c brokerMaxHeapSize=2048M' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerEnableHttp=/c webServerEnableHttp=false' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerEnableHttps=/c webServerEnableHttps=true' ${CS_HOME}/config/cycle_server.properties

### Create the SSH Keystore ###
/bin/keytool -genkey -keyalg RSA -sigalg SHA256withRSA -alias CycleServer -keypass "changeit" -keystore .keystore -storepass "changeit"

echo "Starting CycleCloud..."
${CS_HOME}/cycle_server start --wait
```

### Account and User Setup: ###

At installation time, the script above auto-configures CycleCloud using a set of silent installation / configuration files.

The initial CycleCloud AWS account information is set up in the "cyclecloud_init.txt" file:
https://s3.amazonaws.com/fm-ae1-cyclecloud-poc/installers/6.6.0/cyclecloud_init.txt
The initial set of Users and Groups for CycleCloud access is configured in the "users_init.txt" file:
https://s3.amazonaws.com/fm-ae1-cyclecloud-poc/installers/6.6.0/users_init.txt


**NOTE:**
These files are specific to each operating domain and contain confidential information.   The AWS China installation will need separate copies of these files.


## Cloud Formation: ##

Alternatively, CycleCloud may installed in Master-Slave Failover configuration using the CloudFormation template currently found in S3 at: 
https://s3.console.aws.amazon.com/s3/buckets/fm-ae1-cyclecloud-poc/cloudformation/?region=us-east-1&tab=overview


# Image Building: #

CycleCloud users can use a stock/public image or may build their own following the instructions here: 
https://docs.cyclecomputing.com/administrator-guide-v6.6.0/image_reference

Currently, to we use a custom AMI with Jetpack pre-installed and ENA enabled.
To build the image: 

  1.	Launch and instance of the desired base AMI with ENA enabled from the AWS Console
    a.	The current base image is: CentOS7 R4 w/ ENA (ami-b57350a3)
    b.  Be sure to assign an Instance Role with S3 access to your locker
  2.	Connect to the new instance via SSH
  3.	Remove all un-necessary files
    a.	The current base image includes a pre-installed copy of Univa Grid Engine which should be removed
  4.	Install and software which should be pre-baked into all instances launched by CycleCloud
    a.	Currently, we pre-bake pip and the AWS CLI
    
    ``` bash
     su - 
    yum -y update
    yum -y install epel-release
    yum install -y python-pip java-1.8.0-openjdk.x86_64

    pip install -U pip awscli

    ```
  5.	Download Jetpack (the CycleCloud Agent) and install (as root):
  
  ``` bash
  export CS_VERSION=6.6.0
  mkdir /tmp/installers
  cd /tmp/installers

  aws s3 cp --recursive s3://fm-ae1-cyclecloud-poc/installers/${CC_VERSION}/ .

  tar xzf jetpack*tar.gz
  tar xzf pogo*tar.gz
  mv pogo /usr/local/bin/
  cd jetpack*
  chmod a+x ./install.sh
  ./install.sh
  ```


  6.	Clean up the instance prior to baking (as root): 

  ``` bash
  cd /tmp
  rm -rf /tmp/installers
  passwd -l root
  history -w
  history -c
  exit
  rm -f ~/.ssh/authorized_keys
  history -w
  history -c
  ```

  7.	Bake the image from the AWS Console by selecting the running Instance, right-clicking and selecting "Image -> Create Image" from the context menu. 
  8.	Finally, register the AMI ID for the newly baked image with cyclecloud (where the Version should b (**IMPORTANT** REPLACE the ${REGION} and ${AMI_ID} in the block below with the new AMI ID and the correct Region):

  ``` bash
  Version = "1.0"
  OS = "linux"
  PackageType = "Image"
  AdType = "Package"
  Label = "CentOS7 R4 ENA - CycleCloud"
  Name = "FMI.CENTOS7.R4"

  Virtualization = "hvm"
  Version = "1.0"
  Region = "${REGION}"
  Provider = "aws"
  Package = "FMI.CENTOS7.R4"
  AdType = "Artifact"
  Description = "CentOS7 Cycle R4"
  ImageId = "${AMI_ID}"
  Name = "aws/${REGION}/hvm"
  Size = 30
  AccountName = "cloud"


  ```



# The Chainlink Cluster #

## Projects ##

The Chainlink cluster type relies on two primary CycleCloud projects:

  1.	UGE 
    a.	Installs and Configures Univa Grid Engine 
  2.	Chainlink
    a.	Installs and Configures the Chainlink application


## Chainlink Project Setup ##

  1. Setup Avere subdirectories for the new cluster
    a. [/compbio, /home, /hsq]
  2. Download a copy of the cbio-hpc repository from GitHub and scp to the new CycleCloud instance
  3. SSH to the new CycleCloud instance and sudo to root
  4. Extract the cbio-hpc repository archive to /
  5. Initialize the CycleCloud CLI
    a. `cyclecloud initialize`
  6. Test the CLI
    b. `cyclecloud show_cluster`
  7. Configure access to the Locker for the CLI
  ```
  # Get the list of configured lockers (if you have forgotten the name)
  cyclecloud locker list

  # Append the pogo config section to the end of the config file
  $ vi ~/.cycle/config.ini

  [pogo cloud-storage]
  type = s3
  matches = s3://
  server_side_encryption = true
  use_instance_creds = true
  ```
    
  8. Make a new directory for the UGE Binaries to `/cbio-hpc/cyclecloud_projects/chainlink/specs/default/ge/` and copy the GE tarballs into it.
  9. Upload the Chainlink and UGE Projects to the new Locker:
  ``` bash
  # Get the list of configured lockers (if you have forgotten the name)
  cyclecloud locker list

  # Assuming the locker name is "cloud-storage"
  cd /cbio-hpc/cyclecloud_projects/chainlink
  cyclecloud project upload cloud-storage

  cd /cbio-hpc/cyclecloud_projects/uge
  cyclecloud project upload cloud-storage
  ```
  10. Create a new Parameters file by copying and modifying one of the existing params files in `/cbio-hpc/cyclecloud_projects/clusterParametersFiles`
    a. Check :
      * Avere paths
      * Instance Roles
      * Locker location
      * Account names
      * Project Versions
      * Security Groups
      * Subnets
  11. Import and Start the new cluster.  For example, for the CDX_QA cluster:
  ``` bash
  cyclecloud import_cluster CDX_QA -c chainlink -f /cbio-hpc/cyclecloud_projects/chainlink/templates/chainlink.txt -p /cbio-hpc/cyclecloud_projects/clusterParametersFiles/CDX_QA.params.json

  cyclecloud start_cluster CDX_QA
  ```
  



### Operations: ###

### Common CLI Commands ###

-	Uploading the Projects:
  o	`cyclecloud project upload <target_locker>`
-	Creating and Updating the Clusters:
  o	`cyclecloud import_cluster <ClusterName> -c Chainlink -f ./templates/chainlink.txt -p ./templates/<ClusterParams.json> --force`
-	Starting the Clusters
  o	`cyclecloud start_cluster <ClusterName>`
-	Checking Cluster Status:
  o	`cyclecloud show_cluster <ClusterName>`
-	Terminating the Clusters:
  o	`cyclecloud terminate_cluster <ClusterName>`
-	Deleting the Clusters:
  o	`cyclecloud delete_cluster <ClusterName>`

### When is are Restarts Required? ###

The basic rule of thumb is that infrastructure or software configuration changes require a restart of the node(s) to which the changes apply.

  - If the configuration change applies to the Master node of a UGE cluster, then it is generally safest to terminate and restart the entire cluster.
  - If the configuration change applies only to the Execute nodes, then simple terminate the execute nodes and manually re-add them or allow them to re-autostart.
    - Changes to NodeArrays do not require a terminating existing nodes if it is acceptable for a mix of new and old nodes to co-exist.
  
Changes to cluster parameters and policies often do not require a restart.   For example, it is common to modify the MaxCoreCount parameter dynamically as a run is in-progress to provide additional resources.


### How can I apply Changes **WITHOUT** a Restart? ###

By default, all nodes in the cluster run a periodic (once every 20 minutes) maintainence converge that provides an opportunity to apply changes to running nodes.
It is possible to take advantage of the maintenance converge to apply changes live to existing clusters.

  - Changes to custom Chef recipes which are already in the node's runlist will be applied automatically on the next converge.
  - New custom Chef recipes may be applied to running nodes by adding them to a custom Role which is already in the node's runlist or by including them from a custom Chef recipe which is already in the node's runlist.
  - New Cluster-Init Scripts will be executed the first time they are found by a maintenance converge.
    - A good rule of thumb is just to name the new script so that it is the last script to be executed (scripts execute in lexiographic order).  This tends to help ensure it runs at the right time for new nodes.

**WARNING**
All of these changes will affect **New Nodes** as well as existing nodes.   So take care to ensure that the changes are safe when applied on the first converge as well as on maintenance converge.

**NOTE**
To avoid waiting for a 20 minute interval to expire, you may force an immediate converge by logging in to the node ( `cyclecloud connect -c <cluster_name> <node_name>` ) and running the `jetpack converge` command manually as `root`.


#### What if I need to apply a change to the UGE Master Node without Restart? ###

Changes to the Master may require special handling.
If the steps above, such as creating a new Cluster-Init script to apply the change are too difficult or time consuming (often the case for urgent changes that need to be applied immediately).  Then it is entirely acceptable to modify the running node as if it were an on-premise QMaster.

If you need to apply a manual change, note that some changes may be un-done by the next maintenance converge.  So, good practice is :

  1. First disable maintenance converges.
  ``` bash 
  crontab -e
  # comment out the line which calls **jetpack**
  ```
  2. Make your manual changes to the system and record them.
  3. Test the changes.
  4. Once the changes are working and the urgency is resolved
    a. Go back and update the existing Chef or Cluster-Init scripts to apply the same change
    b. Test the updated Chef or Cluster-Init in Dev
    c. Once you are confident that the changes are safe, **RE-Enable Maintenance Converges**


### What if I need to Restart CycleCloud? ###

In general, CycleCloud may be stopped without impact to running jobs.  There are 3 primary impacts to expect if CycleCloud stops running for a longer period:

  1. Auto-start will stop occuring until CycleCloud is restarted.
     a. Auto-stop will continue to happen when nodes go idle.  This means that you will not incur unnecessary charges.
     b. However, this also means that your pool will eventually reduce in size until only the persistent nodes remain running.  This will impact performance of future jobs until CycleCloud is restarted.
  2. Monitoring for cost and utilization (and historical data collection) will have a gap until CycleCloud is restarted.
  3. Users attempting to view the GUI or execute commands via the CLI will see errors.
  
### What if the CycleCloud host is Terminated? ###

Although rare, it AWS instances sometimes terminate due to host failures, or need to be moved to allow host updates.  

When the CycleCloud host is terminated the following procedure should be followed to restart on a new instance:

  1. If at all possible, shut down the running CycleCloud process before Terminating the current CycleCloud instance.   This will ensure that all data is snapshotted to the data directory.
    `/opt/cycle_server/cycle_server stop`
  2. Start the new instance and mount the existing data volume from the old CycleCloud instance.
  3. Install CycleCloud on the new instance as if this were a completely new installation.
     a. Do NOT start cycle_server yet
  4. Replace the `/opt/cycle_server/data/backups` directory with a symlink to the mounted data volume.
  5. Next, **restore** from backup:
     a. `/opt/cycle_server/util/restore.sh`
  6. Finally, start CycleCloud
     a. `/opt/cycle_server/cycle_server start`

    



## Cluster template vs Cluster-init ##

### User Creation ###

User creation is currently handled by the `create_users` cookbook in the `default` spec (at `Chainlink/specs/default/chef/site-cookbooks/create_users`).  Users may be added or removed by adding/removing a JSON file in `Chainlink/specs/<environment_name>/chef/data_bags/compbio`.

**NOTE**
The `create_users` cookbook is also responsible for moving the default OS user home directories so that CycleCloud is able to mount the shared home directory.

**TBD**
Going forward, we may want to consider switching to Active Directory (perhaps AzureAD as part of the azure pilot) or LDAP for user management.


### FileSystem Mounts ###

Filesystems may be mounted directly via Cluster-Init scripts or Chef, but in the Chainlink project, we're taking advantage of CycleCloud's built-in mount support via the cluster template.  For example this cluster template snippet would mount the `/home` directory on a file system specified by IP Address or Hostname in the `CloudStorageEndpoint` variable:

``` ini
        [[[configuration cyclecloud.mounts.home]]]
        type = nfs
        mountpoint = /home
        export_path = $HomeExport    
        address = $CloudStorageEndpoint
        options = nfsvers=3,tcp,hard,timeo=600,retrans=2,rsize=524288,wsize=524288
        owner = root
        group = compbio
        permissions = "0755"

```

The chainlink template currently mounts all Avere mounts as well as providing the default CycleCloud NFS exports from the Master node.

**NOTE**
It is entirely reasonable to mix an match mounts in the cluster template with mounts from Cluster-Init or Chef.  We have used this in the past to add mounts to running clusters without requiring a cluster restart.


## The Chainlink Project ##

1.	Create_users Cookbook : 
  a.	create_users cookbook
  i.  chown_mounts recipe
  ii.	move_localuser_home recipe
2.	Is this a feature of Jetpack install now?
  a.	fmi.users params
3.	NTP Cookbook
  a.	Fixes custom NTP server list for RHEL/CentOS 7
  b.	Should be able to remove after upgrade
4.	Project per env for users
5.	CreateUsers cookbook
6.	NTP cookbook
7.	Sge_root_symlink -> to match unicloud directory location for uge
8.	MemRes
9.	Sysctl-rpc -> Avere needs custom max rpc ports
10.	Avere Mounts
11.	FMI Sudoers
  a.	Make pipeline user a sudoer
  b.	Allow specific admins to sudo as pipeline user
12.	SGE Request defaults
  a.	Speed up scheduling for non-highmem jobs
13.	SGE Enable lib path
  a.	Chainlink requires oracle libraries that require ENABLE_SUBMIT_LIB_PATH
  b.	Without that, app fails in hard to debug ways
14.	Autoscale.py
  a.	Redirect highmem jobs to slot_type
	

### Other Customizations: ###

1.	Root Device Size
2.	Pipeline User
3.	CycleCloud IAM Roles
  a.	Need 2 (1 for CC, 1 for clusters)
  b.	How should we lock this down for China?
4.	Machine Types
  a.	Master Slot Count 0
  b.	Persistent (always-on) nodes
c.	HighMemMachine
5.	Standalone DNS vs Simple DNS
6.	Univa 8.5 support
7.	FMI Tagging Standard
8.	NOTE on Count vs CoreCount

# Trouble Shooting: #

These are some of the common issues and responses seen with the Chainlink clusters:

1.	A cluster configuration parameter needs to be changed on live clusters:
  a.	See the [When is are Restarts Required?](#when-is-are-restarts-required) section.




