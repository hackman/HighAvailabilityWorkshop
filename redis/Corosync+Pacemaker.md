If you are using Corosync + Pacemake for cluster management, then you can configure Redis, like this:
  primitive ip-74 ocf:heartbeat:IPaddr2 \
        params ip="172.16.31.74" cidr_netmask="24" arp_interval="100" arp_count="20" nic="eth0" arp_bg="yes" \
        op monitor interval="10s" \
        meta target-role="Started" is-managed="true"

  primitive redis ocf:heartbeat:redis \
        params bin="/usr/sbin/redis-server" config="/etc/redis.conf" pidfile_name="redis.pid" client_bin="/usr/bin/redis-cli" user="redis" \
        op monitor interval="10s" role="Master" timeout="10s" on-fail="restart" \
        op monitor interval="12s" role="Slave" timeout="60s" on-fail="restart" \
        op start timeout="120" interval="0" \
        meta is-managed="true" target-role="Started"

  ms ms_redis redis \
        meta master-max="1" target-role="Started" is-managed="true" notify="true"

  colocation ip-74-with-redis inf: ip-74 ms_redis:Master

  order demote-redis_sessions 0: ms_redis:demote ip-74:stop symmetrical=false
  order promote-redis_sessions inf: ip-74:start ms_redis:promote symmetrical=false

The first primitive defines a resource(ip-74), which would be the floating IP, that will go where we promote Redis to Master role.
The secon primitive is the actual Redis service resouce.
The ms line tells Pacemaker, that this would be a Master-Slave resource from the "redis" resouce and there should be only one master of this instance in any given time.
The colocation rule is there, to ensure that this IP is always following the Master redis resource.
The final order rules say, that we want first the redis service to be demoted(made slave) and then ip-74 to be removed from the machine.
Then when we are promoting the resources, we want first the IP to be brought up on the new Master machine and then the redis service to be promoted(remove the slave of part of Redis)
