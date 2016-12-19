#!/bin/bash

export DIRECTOR_IP="REPLACE_ME"                                         # Example: 192.168.1.2
export SSH_USERNAME='REPLACE_ME'                                        # Example: ec2-user
export SSH_PEM_PATH='REPLACE_ME'                                        # Example: ~/aws-cloudera-director.pem
export CLOUDERA_LICENSE_PATH="REPLACE_ME"

export AWS_KEY_ID='REPLACE_ME'
export AWS_SECRET_KEY='REPLACE_ME'
export AWS_REGION='REPLACE_ME'                                          # Example: us-east-1
export AWS_SUBNET_ID='REPLACE_ME'                                       # Example: subnet-XXXXXX
export AWS_SECURITY_GROUP_ID='REPLACE_ME'                               # Example: sg-XXXXXX
export AWS_INSTANCE_PREFIX='REPLACE_ME'

export AWS_AMI_ID='REPLACE_ME'                                          # Example: ami-XXXXXX

export DB_TYPE="REPLACE_ME"                                             # Example: mysql or postgress
export DB_USER='REPLACE_ME'                                             # Example: root
export DB_PASS='REPLACE_ME'
export DB_SUBNET_GROUP_NAME='REPLACE_ME'
export DB_SECURITY_GROUP_ID='REPLACE_ME'
export RDS_INSTANCE_SIZE="REPLACE_ME"                                   # Example: db.m3.medium
export RDS_STORAGE_SIZE="REPLACE_ME"                                    # Example: 100
export RDS_MYSQL_VERSION="REPLACE_ME"                                   # Example: 5.6.27 or 5.5.40b

# The following will install the latest version of the CDH 5.9 release.
export CM_REPO="http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/5.9/"
export CM_REPO_KEY="http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/RPM-GPG-KEY-cloudera"
export CDH_REPO="http://archive.cloudera.com/cdh5/parcels/5.9/"

export CDH_VERSION="5.9.0"

export ENVIRONMENT_NAME="Development"
export CLOUDERA_MANAGER_NAME="CM 5_9"
export CLUSTER_NAME="Enterprise Data Hub"

export DOMAIN='REPLACE_ME'                                              # Example: example.com

export CLUSTER_OWNER="${ENVIRONMENT_NAME}"

export CLUSTER_SERVICES="HDFS, YARN, ZOOKEEPER, HIVE, HUE, OOZIE, SPARK_ON_YARN, IMPALA, FLUME, HBASE, SOLR, SQOOP"

export KERBEROS_ADMIN_USER="REPLACE_ME@${DOMAIN^^}"                     # Example: cloudera@EXAMPLE.COM
export KERBEROS_ADMIN_PASS="REPLACE ME"
export KDC_TYPE="Active Directory"
export KDC_HOST="REPLACE_ME.${DOMAIN}"
export KDC_REALM="${DOMAIN^^}"
export KDC_AD_DOMAIN="REPLACE_ME"                                       # Example: OU=development,OU=cloudera,DC=example,DC=com
export KRB_ENC_TYPES="REPLACE_ME"                                       # Example: aes256-cts aes128-cts arcfour-hmac

export LDAP_ADMIN_USER="REPLACE_ME"
export LDAP_ADMIN_PASS="REPLACE_ME"
export LDAP_URL="REPLACE_ME"                                            # Example: ldaps://ldap-host.example.com:636
export CM_ADMIN_GROUPS="REPLACE_ME"                                     # Example: cloudera-manager-admins
export CM_USER_GROUPS="REPLACE_ME"                                      # Example: cloudera-manager-read-only,cloudera-manager-admins
export NAV_LDAP_URL="REPLACE_ME"                                        # Example: ldaps://ldap-host.example.com
export NAV_ADMIN_GROUPS="REPLACE_ME"                                    # Example: cloudera-navigator-admins
export NAV_LDAP_GROUP_SEARCH_BASE="REPLACE_ME"                          # Example: OU=navigator,OU=cloudera,DC=example,DC=com
export NAV_LDAP_USER_SEARCH_BASE="REPLACE_ME"                           # Example: OU=users,DC=example,DC=com
export HUE_LDAP_URL="REPLACE_ME"                                        # Example: ldap://ldap-host.example.com
export HUE_LDAPS_FLAG="true"                                            # If HUE_LDAP_URL is "ldap" then set this to true for TLS communication.
export HUE_LDAP_ADMIN_USER="${LDAP_ADMIN_USER}@${DOMAIN^^}"             # Example: ldap-admin@EXAMPLE.COM
export HUE_LDAP_SEARCH_BASE="REPLACE_ME"                                # Example: dc=example,dc=com

awk -v CLUSTER_SERVICES="${CLUSTER_SERVICES}" \
    -v CDH_REPO="${CDH_REPO}" \
    '{ 
       sub(/CLUSTER_SERVICES/, CLUSTER_SERVICES);
       sub(/CDH_REPO/, CDH_REPO);
    } 1' /root/director.conf > /root/director-param.conf

export HDFS_SUPERGROUP="REPLACE_ME"                          # Example: hdfs-admins
export HDFS_ADMIN_GROUPS="REPLACE_ME"                        # Example: hadoop,hdfs-admins
export HDFS_AUTHORIZED_GROUPS="REPLACE_ME"                   # Example: hdfs-users,hdfs-admins,hdfs,hadoop,mapred,yarn,impala,hive,hue,spark,zookeeper,httpfs,sqoop,oozie,sentry
export HDFS_NAMESERVICE="REPLACE_ME"                         # Example: nameservice1

export YARN_ADMIN_GROUPS="REPLACE_ME"                        # Example: yarn,yarn-admins

export SENTRY_ADMIN_GROUPS="REPLACE_ME"                      # Example: hive,impala,hue,solr,sentry-admins

export MASTER_HA_NODE_COUNT="2"
export MASTER_NODE_COUNT="1"
export WORKER_NODE_COUNT="4"
export GATEWAY_NODE_COUNT="1"

cloudera-director bootstrap-remote /root/director-param.conf --lp.remote.username=admin --lp.remote.password=admin --lp.remote.hostAndPort=${DIRECTOR_IP}:7189
