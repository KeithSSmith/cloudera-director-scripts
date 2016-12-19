#!/bin/bash
####  This script should run by hand as the MySQL queries have yet to be scripted (to do), the commands are as below

export MASTER_IP="REPLACE_ME"
export SLAVE_IP="REPLACE_ME"
export REPO_IP="REPLACE_ME"
export REPO_PORT="REPLACE_ME"
export SSH_USER="REPLACE_ME"
export PEM_PATH="REPLACE_ME"                                 # Example: /root/privatekey.pem
export MYSQL_ROOT_USER="root"
export MYSQL_ROOT_PASS="REPLACE_ME"
export MYSQL_REPLICATION_USER="replicator"
export MYSQL_REPLICATION_PASS="REPLACE_ME"

###  Download PEM file for SSH access.  ###
wget -O ${PEM_PATH} "http://${REPO_IP}:${REPO_PORT}/ssh/privatekey.pem"
chmod 600 ${PEM_PATH}

###  Setup Master MySQL server.  ###
ssh -oStrictHostKeyChecking=no -i ${PEM_PATH} -t ${SSH_USER}@${MASTER_IP} "sudo sed -e 's/\[mysqld\]/\[mysqld\]\nbind-address=0.0.0.0\nserver-id=1/' /etc/my.cnf > /home/cloudera-scm/my.cnf.ha-master"
ssh -i ${PEM_PATH} -t ${SSH_USER}@${MASTER_IP} "sudo cp /etc/my.cnf /home/cloudera-scm/my.cnf.original"
ssh -i ${PEM_PATH} -t ${SSH_USER}@${MASTER_IP} "sudo cp /home/cloudera-scm/my.cnf.ha-master /etc/my.cnf"
ssh -i ${PEM_PATH} -t ${SSH_USER}@${MASTER_IP} "sudo systemctl restart mariadb"

###  Setup Slave MySQL server.  ###
ssh -oStrictHostKeyChecking=no -i ${PEM_PATH} -t ${SSH_USER}@${SLAVE_IP} "sudo sed -e 's/\[mysqld\]/\[mysqld\]\nbind-address=0.0.0.0\nserver-id=2/' /etc/my.cnf > /home/cloudera-scm/my.cnf.ha-master"
ssh -i ${PEM_PATH} -t ${SSH_USER}@${SLAVE_IP} "sudo cp /etc/my.cnf /home/cloudera-scm/my.cnf.original"
ssh -i ${PEM_PATH} -t ${SSH_USER}@${SLAVE_IP} "sudo cp /home/cloudera-scm/my.cnf.ha-master /etc/my.cnf"
ssh -i ${PEM_PATH} -t ${SSH_USER}@${SLAVE_IP} "sudo systemctl restart mariadb"


###  On Master MariaDB Server  ###
MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'${SLAVE_IP}' IDENTIFIED BY 'REPLACE_ME';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH TABLES WITH READ LOCK;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> SHOW MASTER STATUS;
+-------------------------+----------+--------------+------------------+
| File                    | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+-------------------------+----------+--------------+------------------+
| mysql_binary_log.000005 |      791 |              |                  |
+-------------------------+----------+--------------+------------------+
1 row in set (0.00 sec)


###  On Slave MariaDB Server  ###

MariaDB [(none)]> CHANGE MASTER TO MASTER_HOST='${MASTER_IP}', MASTER_USER='replicator', MASTER_PASSWORD='REPLACE_ME', MASTER_PORT=3306, MASTER_CONNECT_RETRY=30, MASTER_LOG_FILE='REPLACE_ME', MASTER_LOG_POS=REPLACE_ME;
Query OK, 0 rows affected (0.04 sec)

MariaDB [(none)]> START SLAVE;
Query OK, 0 rows affected (0.01 sec)

MariaDB [(none)]> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 
                  Master_User: replicator
                  Master_Port: 3306
                Connect_Retry: 30
              Master_Log_File: mysql_binary_log.000005
          Read_Master_Log_Pos: 791
               Relay_Log_File: mysqld-relay-bin.000002
                Relay_Log_Pos: 536
        Relay_Master_Log_File: mysql_binary_log.000005
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 791
              Relay_Log_Space: 831
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
1 row in set (0.00 sec)

###  On Master MariaDB Server  ###

MariaDB [(none)]> UNLOCK TABLES;
Query OK, 0 rows affected (0.00 sec)



###  Run these to give the root user access from any location.  ###

MariaDB [(none)]> DELETE FROM mysql.user WHERE user = "root" AND host = "::1";
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> UPDATE mysql.user SET host = "%" WHERE user = "root" AND host = "127.0.0.1";
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

MariaDB [(none)]> DELETE FROM mysql.user WHERE user = "root" AND host = "localhost";
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.01 sec)
