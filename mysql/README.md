
Setting up MySQL replication: https://dev.mysql.com/doc/refman/5.7/en/replication-howto.html

You can use the my.cnf provided in this dir, but keep in mind that you need to create /var/log/mysql

Possible ways to copy the DB: https://dev.mysql.com/doc/refman/5.7/en/replication-snapshot-method.html

Dump all databases with mysqldump:
 mysqldump --all-databases --master-data > dbdump.db

In the dump, there should be a line like this one:
 CHANGE MASTER TO MASTER_LOG_FILE='binary.000001', MASTER_LOG_POS=154;

If you are using LVM:
 mysql_commands="
 SET GLOBAL READ_ONLY=ON;
 FLUSH TABLES WITH READ LOCK;
 SELECT SLEEP(5);
 SHOW MASTER STATUS;
 SYSTEM lvcreate -s -L50G -n dbsnap /dev/VolGroup00/db
 SET GLOBAL READ_ONLY=OFF;
 UNLOCK TABLES;
 "
 mysql -e "$mysql_commands" > master.status

Or you can shutdown MySQL and rsync all the data from one machine to the other.


On the master server:  https://dev.mysql.com/doc/refman/5.7/en/replication-howto-masterstatus.html
 mysql> SHOW MASTER STATUS;

Make sure that the servers are with different server_ids:
 mysql> SHOW VARIABLES LIKE 'server_id';

Make sure that the slave replication user is correctly setup on the Master server:
 mysql> SHOW GRANTS for replica@172.16.31.1;
If the user is missing or with worng IP/Pass:
 mysql> GRANT REPLICATION SLAVE ON *.* TO replica@172.16.31.1 IDENTIFIED BY '981urfjk1mdpsc90813(#';

If you use IDENTIFIED BY PASSSWORD, this means, that you are providing the password hash, not the actual password.

On the slave server: https://dev.mysql.com/doc/refman/5.7/en/replication-setup-slaves.html
 mysql> RESET SLAVE;
 mysql> CHANGE MASTER TO MASTER_HOST='172.16.31.12', MASTER_USER='replica', MASTER_PASSWORD='13087hod1lmc<83017gdy>oewe2nd', MASTER_LOG_FILE='binary.001141', MASTER_LOG_POS=107;
 mysql> SHOW SLAVE STATUS\G
 mysql> START SLAVE;
 mysql> SHOW SLAVE STATUS\G
