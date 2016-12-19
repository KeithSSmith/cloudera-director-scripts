# Cloudera Director with Security Integration

This is a collection of scripts to help automate the build process of Cloudera Director in the Cloud.  When modifying these scripts the REPLACE_ME tag has been used so it is best to find and replace with the appropriate values.

This script requires many security and networking pieces to be ready to go.  It is assumed that AD is used as the KDC, that you want to build and maintain an internal repo, and that a DNS server is allowed to be updated via the commands used in the script (nsupdate).


## Azure Overview

The Azure build assumes that you will be using external MySQL instances with Master/Slave replication, internally built repositories, a DNS server that the new VM's can update to, an Active Directory domain controller that the OS can join to, an OU in AD that can be used to store service accounts, LDAPS configured for LDAP query security, Groups defined in AD that define permissions for various Hadoop services, and an Azure service account setup with the proper permissions and keys as well as resources built to allow for parameter substitution.

## AWS Overview

The AWS build assumes that you will be using an RDS MySQL instance, external Cloudera repositories, the AWS internal DNS server, an Active Directory domain controller that the OS can join to, an OU in AD that can be used to store service accounts, LDAPS configured for LDAP lookup security, Groups defined in AD that define permissions for various Hadoop services, and AWS credentials with all resources built to allow for paramenter substitution.
