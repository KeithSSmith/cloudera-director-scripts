#!/bin/bash

###  Define Variables  ###
HOST_IP_ADDRESS=$(ip addr | grep eth0 -A2 | head -n3 | tail -n1 | awk -F'[/ ]+' '{print $3}')
HOSTNAME=$(hostname)
DOMAIN="REPLACE_ME"                                          # Example: example.com
DOMAIN_CONTROLLER="REPLACE_ME.${DOMAIN}"
DNS_IP="REPLACE_ME"
AD_JOIN_USER="REPLACE_ME"
AD_JOIN_PASS='REPLACE_ME'
DNS_JOIN_USER="REPLACE_ME"
DNS_JOIN_PASS="REPLACE_ME"
#HTTP_PROXY_USER="REPLACE_ME"
#HTTP_PROXY_PASS="REPLACE_ME"
#HTTP_PROXY_ADDRESS="REPLACE_ME"
#HTTP_PROXY_PORT="REPLACE_ME"
MYSQL_ROOT_PASS="REPLACE_ME"
DIRECTOR_DB_NAME="REPLACE_ME"
DIRECTOR_DB_USER="REPLACE_ME"
DIRECTOR_DB_PASS="REPLACE_ME"

HTTP_CONF=$(mktemp -t http_conf.XXXXXXXXXX)
MYSQL_CONF=$(mktemp -t mysql_conf.XXXXXXXXXX)
KRB5_CONF=$(mktemp -t krb5_conf.XXXXXXXXXX)
NTP_CONF=$(mktemp -t ntp_conf.XXXXXXXXXX)
SSSD_CONF=$(mktemp -t sssd_conf.XXXXXXXXXX)
SSHD_CONF=$(mktemp -t sshd_conf.XXXXXXXXXX)

###  Ensure the Node and YUM are up to date.  ###
yum clean all
yum makecache fast
yum -y update
yum -y install bind-utils wget telnet redhat-lsb-core mariadb-server nscd ntp httpd

###  Configure Apache WebServer for Port 90 and on restart.  ###
sed -e 's/^Listen 80/Listen 90/' /etc/httpd/conf/httpd.conf > ${HTTP_CONF}
cat ${HTTP_CONF} > /etc/httpd/conf/httpd.conf
systemctl restart httpd
systemctl enable httpd

###  Set SELinux to permissive  ###
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

###  Make private key downloadable  ###
mkdir -p /var/www/html/ssh
echo "-----BEGIN RSA PRIVATE KEY-----
REPLACE_ME
-----END RSA PRIVATE KEY-----" > /var/www/html/ssh/privatekey.pem    ### This needs to be the private key that can be used to SSH between nodes via keys.

###  Turn Proxy On (if needed)  ####
#export http_proxy="http://${HTTP_PROXY_USER}:${HTTP_PROXY_PASS}@${HTTP_PROXY_ADDRESS}:${HTTP_PROXY_PORT}"
#export https_proxy="https://${HTTP_PROXY_USER}:${HTTP_PROXY_PASS}@${HTTP_PROXY_ADDRESS}:${HTTP_PROXY_PORT}"

###  Build Director, CM, CDH, and Miscellaneous repository  ###
###  Download Cloudera Manager 5.8.3 Repository  ###
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/RPM-GPG-KEY-cloudera
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/5.8.3/

###  Download CDH 5.8.3 Repository  ###
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/cdh5/parcels/5.8.3/CDH-5.8.3-1.cdh5.8.3.p0.2-el7.parcel
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/cdh5/parcels/5.8.3/CDH-5.8.3-1.cdh5.8.3.p0.2-el7.parcel.sha1
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/cdh5/parcels/5.8.3/manifest.json

###  Download Cloudera Director 2.2.0 Repository  ###
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/director/redhat/7/x86_64/director/cloudera-director.repo
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/director/redhat/7/x86_64/director/RPM-GPG-KEY-cloudera
wget -e robots=off -r --no-parent -P /var/www/html/ http://archive.cloudera.com/director/redhat/7/x86_64/director/2.2.0/

###  Download MySQL JDBC Connector  ###
wget -P /var/www/html/dev.mysql.com/Connector-J/ http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.40.tar.gz

###  Download Oracle Java 8 Unlimited JCE Policy Files.  ###
wget -P /var/www/html/download.oracle.com/otn-pub/java/jce/8/ --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip"

###  Turn Proxy Off (if needed)  ##
#unset http_proxy
#unset https_proxy



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



###  Configure MariaDB with Cloudera recommended settings, particularly InnoDB support, can be found at: http://www.cloudera.com/documentation/enterprise/latest/topics/install_cm_mariadb.html  ###
echo "[mysqld]
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
symbolic-links = 0

key_buffer = 16M
key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1
max_connections = 550
#expire_logs_days = 10
#max_binlog_size = 100M

#log_bin should be on a disk with enough free space. Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your system
#and chown the specified folder to the mysql user.
log_bin=/var/lib/mysql/mysql_binary_log

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mariadb/mysql.log
pid-file=/var/run/mariadb/mysqld.pid
" > "${MYSQL_CONF}"
cat "${MYSQL_CONF}" > /etc/my.cnf

###  Start MariaDB and Enable it on Startup  ###
systemctl start mariadb
systemctl enable mariadb

###  Secure MariaDB by setting a root password, removing anonymous users, remove test database, and reload these privileges.  ###
/usr/bin/mysql_secure_installation <<EOF

y
${MYSQL_ROOT_PASS}
${MYSQL_ROOT_PASS}
y
n
y
y
EOF

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

systemctl restart httpd
