#!/bin/bash

###  Define Variables  ###
HOST_IP_ADDRESS=$(ip addr | grep eth0 -A2 | head -n3 | tail -n1 | awk -F'[/ ]+' '{print $3}')
HOSTNAME=$(hostname)
DOMAIN="REPLACE_ME"                                          # Example: example.com
DOMAIN_CONTROLLER="REPLACE_ME.${DOMAIN}"                     # Example: dc1.example.com
DNS_IP="REPLACE_ME"
AD_JOIN_USER="REPLACE_ME"
AD_JOIN_PASS="REPLACE_ME"
DNS_JOIN_USER="REPLACE_ME"
DNS_JOIN_PASS="REPLACE_ME"
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASS="REPLACE_ME"
MYSQL_IP="REPLACE_ME"                                        #  NEEDS to point to MASTER MySQL Instance IP
DIRECTOR_DB_TYPE="mysql"
DIRECTOR_DB_NAME="REPLACE_ME"
DIRECTOR_DB_USER="REPLACE_ME"
DIRECTOR_DB_PASS="REPLACE_ME"
DIRECTOR_DB_PORT="3306"
REPO_IP="REPLACE_ME"
REPO_PORT="REPLACE_ME"

DIRECTOR_PROPERTIES=$(mktemp -t director_properties.XXXXXXXXXX)
DIRECTOR_REPO=$(mktemp -t director_repo.XXXXXXXXXX)
KRB5_CONF=$(mktemp -t krb5_conf.XXXXXXXXXX)
NTP_CONF=$(mktemp -t ntp_conf.XXXXXXXXXX)
SSSD_CONF=$(mktemp -t sssd_conf.XXXXXXXXXX)
SSHD_CONF=$(mktemp -t sshd_conf.XXXXXXXXXX)

###  Ensure the Node and YUM are up to date.  ###
yum clean all
yum makecache fast
yum -y update
yum -y install bind-utils wget telnet redhat-lsb-core nscd rng-tools ntp mariadb

###  Set SELinux to permissive  ###
sed -i.bak "s/^SELINUX=.*$/SELINUX=disabled/" /etc/selinux/config
setenforce 0

###  Disable tuned so it does not overwrite sysctl.conf  ###
service tuned stop
systemctl disable tuned

###  Disable chrony so it does not conflict with ntpd installed by Director  ###
systemctl stop chronyd
systemctl disable chronyd

###  Update config to disable IPv6 and disable  ###
echo "# Disable IPv6" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

# swappniess is set by Director in /etc/sysctl.conf
# Poke sysctl to have it pickup the config change.
sysctl -p

###  Turn off iptables  ###
systemctl stop firewalld
systemctl disable firewalld

###  Turn on NTP with internal NTP Server  ###
sed -e 's/server 0.rhel.pool.ntp.org iburst/#server 0.rhel.pool.ntp.org iburst/' \
 -e 's/server 1.rhel.pool.ntp.org iburst/#server 1.rhel.pool.ntp.org iburst/' \
 -e 's/server 2.rhel.pool.ntp.org iburst/#server 2.rhel.pool.ntp.org iburst/' \
 -e "s/server 3.rhel.pool.ntp.org iburst/#server 3.rhel.pool.ntp.org iburst\n# NTP Server defined manually.\nserver ${DOMAIN_CONTROLLER} prefer/" \
 /etc/ntp.conf > ${NTP_CONF}

cat ${NTP_CONF} > /etc/ntp.conf
systemctl restart ntpd
ntpdate -u ${DOMAIN_CONTROLLER}

###  Update Timezone  ###
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/US/Central /etc/localtime

###  Set SELinux to permissive  ###
setenforce 0

###  Download and Install the MySQL Java Connector  ###
wget "http://${REPO_IP}:${REPO_PORT}/dev.mysql.com/Connector-J/mysql-connector-java-5.1.40.tar.gz" -O /tmp/mysql-connector-java-5.1.40.tar.gz
tar zxvf /tmp/mysql-connector-java-5.1.40.tar.gz -C /tmp/
mkdir -p /usr/share/java/
cp /tmp/mysql-connector-java-5.1.40/mysql-connector-java-5.1.40-bin.jar /usr/share/java/
rm /usr/share/java/mysql-connector-java.jar
ln -s /usr/share/java/mysql-connector-java-5.1.40-bin.jar /usr/share/java/mysql-connector-java.jar


###  Install Cloudera Director and Java 8  ###
echo "[cloudera-director]
# Packages for Cloudera Director, Version 2, on RedHat or CentOS 7 x86_64
name=Cloudera Director
baseurl=http://${REPO_IP}:${REPO_PORT}/archive.cloudera.com/director/redhat/7/x86_64/director/2.2.0/
gpgkey = http://${REPO_IP}:${REPO_PORT}/archive.cloudera.com/director/redhat/7/x86_64/director/RPM-GPG-KEY-cloudera
gpgcheck = 1
enabled=1" > "${DIRECTOR_REPO}"

cat "${DIRECTOR_REPO}" > /etc/yum.repos.d/cloudera-director.repo

rpm --import "http://${REPO_IP}:${REPO_PORT}/archive.cloudera.com/director/redhat/7/x86_64/director/RPM-GPG-KEY-cloudera"

yum clean all
yum makecache fast
yum -y install java --nogpgcheck

###  Install Java Unlimited Strength Encryption Policy Files for Java 8  ###
wget -O /tmp/jce_policy-8.zip "http://${REPO_IP}:${REPO_PORT}/download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip"
unzip /tmp/jce_policy-8.zip -d /tmp
rm -f /usr/java/jdk1.8.0_60/jre/lib/security/local_policy.jar
rm -f /usr/java/jdk1.8.0_60/jre/lib/security/US_export_policy.jar
mv /tmp/UnlimitedJCEPolicyJDK8/local_policy.jar /usr/java/jdk1.8.0_60/jre/lib/security/local_policy.jar
mv /tmp/UnlimitedJCEPolicyJDK8/US_export_policy.jar /usr/java/jdk1.8.0_60/jre/lib/security/US_export_policy.jar

yum -y install cloudera-director-server cloudera-director-client

###  Create the director database and director user.   ###
mysql -h ${MYSQL_IP} -u ${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASS} -e "CREATE DATABASE ${DIRECTOR_DB_NAME} DEFAULT CHARACTER SET utf8"
mysql -h ${MYSQL_IP} -u ${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASS} -e "GRANT ALL ON ${DIRECTOR_DB_NAME}.* TO '"${DIRECTOR_DB_USER}"'@'"${HOST_IP_ADDRESS}"' IDENTIFIED BY '"${DIRECTOR_DB_PASS}"' WITH GRANT OPTION"


###  Configure Director Server to use MariaDB for Metadata Storage.  ###
sed -e "s/# lp.database.type: mysql/lp.database.type: ${DIRECTOR_DB_TYPE}/" \
 -e "s/# lp.database.username:/lp.database.username: ${DIRECTOR_DB_USER}/" \
 -e "s/# lp.database.password:/lp.database.password: ${DIRECTOR_DB_PASS}/" \
 -e "s/# lp.database.host:/lp.database.host: ${MYSQL_IP}/" \
 -e "s/# lp.database.port:/lp.database.port: ${DIRECTOR_DB_PORT}/" \
 -e "s/# lp.database.name:/lp.database.name: ${DIRECTOR_DB_NAME}/" \
 /etc/cloudera-director-server/application.properties > "${DIRECTOR_PROPERTIES}"
cat "${DIRECTOR_PROPERTIES}" > /etc/cloudera-director-server/application.properties


###  Start Cloudera Director Server and Enable it on Startup  ###
systemctl start cloudera-director-server
systemctl enable cloudera-director-server


###  Install Packages needed for SSSD, DNS, LDAP, and Kerberos  ###
yum -y install realmd sssd sssd-ad samba-common adcli sssd-libwbclient openldap-devel openldap-clients pam_krb5 samba-common-tools krb5-workstation

###  Update resolv.conf  ###
echo "search ${DOMAIN}" >> /etc/resolv.conf

###  Change /etc/krb5.conf ###
echo "[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log


[libdefaults]
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 default_realm = ${DOMAIN^^}
 default_ccache_name = FILE:/tmp/krb5cc_%{uid}
 udp_preference_limit = 1


[realms]
 ${DOMAIN^^} = {
  kdc = ${DOMAIN_CONTROLLER}
  admin_server = ${DOMAIN_CONTROLLER}
 }


[domain_realm]
 .${DOMAIN} = ${DOMAIN^^}
 ${DOMAIN} = ${DOMAIN^^}
" > "${KRB5_CONF}"
cat "${KRB5_CONF}" > /etc/krb5.conf


###  Join the computer to the domain.  ###
realm discover ${DOMAIN^^}
realm join ${DOMAIN^^} -U "${AD_JOIN_USER}" --verbose --computer-ou='OU=Cloudera' <<EOF
${AD_JOIN_PASS}
EOF

###  Configure SSSD and SSH configuration.  ###
sed -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/' \
 -e 's|fallback_homedir = /home/%u@%d|fallback_homedir = /home/%u|' \
 -e 's|services = nss, pam|services = nss, pam\n\n[nss]\noverride_homedir = /home/%u\ndefault_shell = /bin/bash|' \
 /etc/sssd/sssd.conf > ${SSSD_CONF}

cat ${SSSD_CONF} > /etc/sssd/sssd.conf
rm -f /var/lib/sss/db/*
rm -f /var/lib/sss/mc/*
systemctl restart sssd

sed -e 's/PasswordAuthentication no/PasswordAuthentication yes/' \
 -e 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' \
 /etc/ssh/sshd_config > ${SSHD_CONF}

cat ${SSHD_CONF} > /etc/ssh/sshd_config
systemctl restart sshd

###  Create DHCP Exit Hooks File to update DNS entries and restart the network.  ###
# https://github.com/cloudera/director-scripts/blob/master/azure-dns-scripts/bootstrap_dns_nm.sh
# RHEL 7.2 uses NetworkManager. Add a script to be automatically invoked when interface comes up.
cat > /etc/NetworkManager/dispatcher.d/12-register-dns <<"EOF"
#!/bin/bash
# NetworkManager Dispatch script
# Deployed by Cloudera Director Bootstrap
#
# Expected arguments:
#    $1 - interface
#    $2 - action
#
# See for info: http://linux.die.net/man/8/networkmanager
# Register A and PTR records when interface comes up
# only execute on the primary nic
if [[ "$1" != "eth0" || "$2" != "up" ]]
then
    exit 0;
fi
# when we have a new IP, perform nsupdate
new_ip_address="$DHCP4_IP_ADDRESS"
host=$(hostname -s)
domain=$(hostname | cut -d'.' -f2- -s)
domain=${domain:='cdh-cluster.internal'} # REPLACE_ME If no hostname is provided, use cdh-cluster.internal
IFS='.' read -ra ipparts <<< "$new_ip_address"
ptrrec="$(printf %s "$new_ip_address." | tac -s.)in-addr.arpa"
nsupdatecmds=$(mktemp -t nsupdate.XXXXXXXXXX)
resolvconfupdate=$(mktemp -t resolvconfupdate.XXXXXXXXXX)
echo updating resolv.conf
grep -iv "search" /etc/resolv.conf > "$resolvconfupdate"
echo "search reddog.microsoft.com" >> "$resolvconfupdate"
echo "search $domain" >> "$resolvconfupdate"
cat "$resolvconfupdate" > /etc/resolv.conf
echo "Attempting to register $host.$domain and $ptrrec"
{
    echo "update delete $host.$domain a"
    echo "update add $host.$domain 600 a $new_ip_address"
    echo "send"
    echo "update delete $ptrrec ptr"
    echo "update add $ptrrec 600 ptr $host.$domain"
    echo "send"
} > "$nsupdatecmds"
nsupdate -g "$nsupdatecmds"
exit 0;
EOF
chmod 755 /etc/NetworkManager/dispatcher.d/12-register-dns
kinit ${DNS_JOIN_USER} <<EOF
${DNS_JOIN_PASS}
EOF
systemctl restart NetworkManager
systemctl restart network

## Enable and start nscd
chkconfig nscd on
service nscd start
