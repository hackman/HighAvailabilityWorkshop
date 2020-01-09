-- Setup base configuration of the proxy
UPDATE global_variables SET variable_value='127.0.0.1:3306' WHERE variable_name='mysql-interfaces';
UPDATE global_variables SET variable_value='proxysql'		WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='proxysql'		WHERE variable_name='mysql-monitor_password';
UPDATE global_variables SET variable_value='100'			WHERE variable_name='mysql-max_stmts_per_connection';
UPDATE global_variables SET variable_value='5000'			WHERE variable_name='mysql-monitor_connect_interval';
UPDATE global_variables SET variable_value='1200'			WHERE variable_name='mysql-monitor_ping_interval';
UPDATE global_variables SET variable_value='1000'			WHERE variable_name='mysql-monitor_read_only_interval';
UPDATE global_variables SET variable_value='50'				WHERE variable_name='mysql-shun_on_failures';
UPDATE global_variables SET variable_value='1'				WHERE variable_name='mysql-handle_unknown_charset';
UPDATE global_variables SET variable_value='1'				WHERE variable_name='mysql-use_tcp_keepalive';
UPDATE global_variables SET variable_value='1'				WHERE variable_name='mysql-show_processlist_extended';
UPDATE global_variables SET variable_value='360'			WHERE variable_name='mysql-tcp_keepalive_time';
UPDATE global_variables SET variable_value='true'			WHERE variable_name='mysql-verbose_query_error';
UPDATE global_variables SET variable_value='5.5.62'			WHERE variable_name='mysql-server_version';
SAVE MYSQL VARIABLES TO DISK;
LOAD MYSQL VARIABLES TO RUNTIME;
-- Disable hashed passwords in ProxySQL to allow plain text passwords
UPDATE global_variables SET variable_value='false' WHERE variable_name='admin-hash_passwords';
SAVE ADMIN VARIABLES TO DISK;
LOAD ADMIN VARIABLES TO RUNTIME;
-- Add the backend servers and create the replication group
INSERT INTO mysql_servers(hostgroup_id,hostname,port) VALUES (1,'172.16.31.1',3306);
INSERT INTO mysql_servers(hostgroup_id,hostname,port) VALUES (1,'172.16.31.2',3306);
INSERT INTO mysql_servers(hostgroup_id,hostname,port) VALUES (1,'172.16.31.3',3306);
INSERT INTO mysql_replication_hostgroups VALUES (1,2,'read_only','wp-cluster');
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
-- Add the users that should be able to connect to the backend servers
INSERT INTO mysql_users(username,password,default_hostgroup) VALUES ('wpsys','(TO@!d-1heou1v31`2360pj',1);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
