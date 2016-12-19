#!/bin/bash

export DIRECTOR_IP="REPLACE_ME"                              # Example: 192.168.1.2
export SSH_USERNAME='REPLACE_ME'                             # Example: cloudera-scm
export SSH_PEM_PATH='REPLACE_ME'                             # Can be used if you don't want to paste the PEM contents in director.conf
export CLOUDERA_LICENSE_PATH="REPLACE_ME"

export TAGS_OWNER="REPLACE_ME"                               # These can be used for tagging Azure instances for tracking purposes (if necessary)
export TAGS_PROJECT="REPLACE_ME"

export AZURE_REGION='REPLACE_ME'                             # https://azure.microsoft.com/en-us/regions/services/
export AZURE MGMT_URL='https://management.core.windows.net/'
export AZURE_AD_URL='https://login.windows.net/'
export AZURE_SUBSCRIPTION_ID='REPLACE_ME'                    # http://www.cloudera.com/documentation/director/latest/topics/director_get_started_azure_obtain_credentials.html#concept_jrx_gfp_hw
export AZURE_TENANT_ID='REPLACE_ME'                          # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal
export AZURE_CLIENT_ID='REPLACE_ME'
export AZURE_CLIENT_SECRET='REPLACE_ME'

export AZURE_NODE_SIZE='STANDARD_DS13'                       # Options: STANDARD_DS15_V2, STANDARD_DS14, STANDARD_DS14_V2, STANDARD_DS13, STANDARD_DS13_V2, STANDARD_DS12_V2, STANDARD_GS5, or STANDARD_GS4
export AZURE_OS='redhat-rhel-72-latest'                      # Options: cloudera-centos-6-latest, cloudera-centos-72-latest, redhat-rhel-67-latest, or redhat-rhel-72-latest
export AZURE_NETWORK_SG_RG='REPLACE_ME'                      # Example: net-sg-rg-cloudera
export AZURE_NETWORK_SG='REPLACE_ME'                         # Example: net-sg-cloudera
export AZURE_VNET_RG='REPLACE_ME'                            # Example: vnet-rg-cloudera
export AZURE_VNET='REPLACE_ME'                               # Example: nvet-cloudera
export AZURE_SUBNET='TREPLACE_ME'                            # Example: sn-cloudera

export AZURE_COMPUTE_RG='REPLACE_ME'                         # Example: rg-cloudera
export AZURE_AVAILABILITY_SET='REPLACE_ME'                   # Example: as-cloudera-v2 or as-cloudera-v1  Need different availability sets for different node types.
export AZURE_PUBLIC_IP='No'                                  # Options: Yes or No

export AZURE_MGMT_NAME_PREFIX='mgmt'
export AZURE_MGMT_STORAGE_TYPE='StandardLRS'                 # Options: PremiumLRS or StandardLRS
export AZURE_MGMT_DISK_SIZE='512'                            # Options: 1023 or 512
export AZURE_MGMT_DISK_COUNT='1'

export AZURE_MASTER_NAME_PREFIX='master'
export AZURE_MASTER_STORAGE_TYPE='PremiumLRS'                # Options: PremiumLRS or StandardLRS
export AZURE_MASTER_DISK_SIZE='512'                          # Options: 1023 or 512
export AZURE_MASTER1_DISK_COUNT='4'
export AZURE_MASTER2_DISK_COUNT='3'

export AZURE_WORKER_NAME_PREFIX='worker'
export AZURE_WORKER_STORAGE_TYPE='StandardLRS'               # Options: PremiumLRS or StandardLRS
export AZURE_WORKER_DISK_SIZE='512'                          # Options: 1023 or 512
export AZURE_WORKER_DISK_COUNT='11'

export AZURE_EDGE_NAME_PREFIX='edge'
export AZURE_EDGE_STORAGE_TYPE='StandardLRS'                 # Options: PremiumLRS or StandardLRS
export AZURE_EDGE_DISK_SIZE='512'                            # Options: 1023 or 512
export AZURE_EDGE_DISK_COUNT='1'

export DOMAIN='REPLACE_ME'                                   # Example: example.com

export DB_TYPE='REPLACE_ME'                                  # Options: mysql or postgresql
export DB_IP='REPLACE_ME'                                    # Static IP of the external database
export DB_PORT='REPLACE_ME'                                  # Example: 3306 if using mysql
export DB_USER='REPLACE_ME'                                  # This should be a user with the ability to create databases and users with grant privileges, essentially root or can be root.
export DB_PASS='REPLACE_ME'

export REPO_IP="REPLACE_ME"
export REPO_PORT="REPLACE_ME"
export CM_REPO="http://${REPO_IP}:${REPO_PORT}/archive.cloudera.com/cm5/redhat/7/x86_64/cm/5.8.3/"
export CM_REPO_KEY="http://${REPO_IP}:${REPO_PORT}/archive.cloudera.com/cm5/redhat/7/x86_64/cm/RPM-GPG-KEY-cloudera"
export CDH_REPO="http://${REPO_IP}:${REPO_PORT}/archive.cloudera.com/cdh5/parcels/5.8.3/"
export CDH_VERSION="5.8.3"
export CLUSTER_SERVICES="REPLACE_ME"                         # Example: HDFS, YARN, ZOOKEEPER, HIVE, HUE, OOZIE, SPARK_ON_YARN, IMPALA, FLUME, HBASE, SOLR, SQOOP

export ENVIRONMENT_NAME="Development"
export CLOUDERA_MANAGER_NAME="CM 5_8"
export CLUSTER_NAME="Enterpise Data Hub"

export KERBEROS_ADMIN_USER="REPLACE_ME@${DOMAIN^^}"          # Example: cloudera@EXAMPLE.COM
export KERBEROS_ADMIN_PASS="REPLACE ME"
export KDC_TYPE="Active Directory"
export KDC_HOST="REPLACE_ME.${DOMAIN}"
export KDC_REALM="${DOMAIN^^}"
export KDC_AD_DOMAIN="REPLACE_ME"                            # Example: OU=development,OU=cloudera,DC=example,DC=com
export KRB_ENC_TYPES="REPLACE_ME"                            # Example: aes256-cts aes128-cts arcfour-hmac
export DNS_JOIN_USER="REPLACE_ME"                            # User with permissions to update the DNS server.
export DNS_JOIN_PASS="REPLACE_ME"

export LDAP_ADMIN_USER="REPLACE_ME"
export LDAP_ADMIN_PASS="REPLACE_ME"
export LDAP_URL="REPLACE_ME"                                 # Example: ldaps://ldap-host.example.com:636
export CM_ADMIN_GROUPS="REPLACE_ME"                          # Example: cloudera-manager-admins
export CM_USER_GROUPS="REPLACE_ME"                           # Example: cloudera-manager-read-only,cloudera-manager-admins
export NAV_LDAP_URL="REPLACE_ME"                             # Example: ldaps://ldap-host.example.com
export NAV_ADMIN_GROUPS="REPLACE_ME"                         # Example: cloudera-navigator-admins
export NAV_LDAP_GROUP_SEARCH_BASE="REPLACE_ME"               # Example: OU=navigator,OU=cloudera,DC=example,DC=com
export NAV_LDAP_USER_SEARCH_BASE="REPLACE_ME"                # Example: OU=users,DC=example,DC=com
export HUE_LDAP_URL="REPLACE_ME"                             # Example: ldap://ldap-host.example.com
export HUE_LDAPS_FLAG="true"                                 # If HUE_LDAP_URL is "ldap" then set this to true for TLS communication.
export HUE_LDAP_ADMIN_USER="${LDAP_ADMIN_USER}@${DOMAIN^^}"  # Example: ldap-admin@EXAMPLE.COM
export HUE_LDAP_SEARCH_BASE="REPLACE_ME"                     # Example: dc=example,dc=com

awk -v CDH_REPO="${CDH_REPO}" \
    -v CLUSTER_SERVICES="${CLUSTER_SERVICES}" \
    '{
       sub(/CDH_REPO/, CDH_REPO);
       sub(/CLUSTER_SERVICES/, CLUSTER_SERVICES);
    } 1' /root/director.conf > /root/director-param.conf


export HDFS_SUPERGROUP="REPLACE_ME"                          # Example: hdfs-admins
export HDFS_ADMIN_GROUPS="REPLACE_ME"                        # Example: hadoop,hdfs-admins
export HDFS_AUTHORIZED_GROUPS="REPLACE_ME"                   # Example: hdfs-users,hdfs-admins,hdfs,hadoop,mapred,yarn,impala,hive,hue,spark,zookeeper,httpfs,sqoop,oozie,sentry
export HDFS_NAMESERVICE="REPLACE_ME"                         # Example: nameservice1

export YARN_ADMIN_GROUPS="REPLACE_ME"                        # Example: yarn,yarn-admins

export SENTRY_ADMIN_GROUPS="REPLACE_ME"                      # Example: hive,impala,hue,solr,sentry-admins

export MASTER_HA_NODE_COUNT="2"
export MASTER_NODE_COUNT="1"
export WORKER_NODE_COUNT="5"
export GATEWAY_NODE_COUNT="1"

cloudera-director bootstrap-remote /root/director-param.conf --lp.remote.username=admin --lp.remote.password=admin --lp.remote.hostAndPort=${DIRECTOR_IP}:7189
