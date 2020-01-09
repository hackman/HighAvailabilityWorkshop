If you are using Corosync + Pacemake for cluster management, then you can configure Redis, like this:
  primitive ip-56 ocf:heartbeat:IPaddr2 \
        params ip="172.16.31.56" cidr_netmask="24" arp_interval="100" arp_count="20" nic="eth0" arp_bg="yes" \
        op monitor interval="10s" \
        meta target-role="Started" is-managed="true"

  primitive mysql ocf:heartbeat:mysql \
        params binary="/usr/bin/mysqld_safe" config="/etc/my.cnf" datadir="/var/lib/mysql" socket="/var/lib/mysql/mysql.sock" pid="/var/lib/mysql/mysqld.pid" test_user="root" test_passwd="PASSMETOMATOES" replication_user="replica" replication_passwd="(*)@!J!I(jd187" \
        op start timeout="20" interval="0" \
        op stop timeout="20" interval="0" \
        op promote timeout="10" interval="0" \
        op demote timeout="10" interval="0" \
        op monitor interval="1s" role="Master" timeout="10s" on-fail="restart" \
        op monitor interval="2s" role="Slave" timeout="10s" on-fail="restart" \
        meta is-managed="true"

  ms ms_mysql mysql \
        meta master-max="1" target-role="Master" is-managed="false" notify="true"

  colocation ip-56-with-mysql-site inf: ip-56 ms_mysql:Master

  order demote-site 0: ms_mysql:demote ip-56:stop symmetrical=false
  order promote-site inf: ip-56:start ms_mysql:promote symmetrical=false


The first primitive defines a resource(ip-56), which would be the floating IP, that will go where we promote MySQL to Master role.
The secon primitive is the actual MySQL service resouce.
The ms line tells Pacemaker, that this would be a Master-Slave resource from the "mysql" resouce and there should be only one master of this instance in any given time.
The colocation rule is there, to ensure that this IP is always following the Master MySQL resource.
The final order rules say, that we want first the MySQL service to be demoted(made read-only) and then ip-56 to be removed from the machine.
Then when we are promoting the resources, we want first the IP to be brought up on the new Master machine and then the MySQL service to be promoted(RESET SLAVE; READ-ONLY OFF)

