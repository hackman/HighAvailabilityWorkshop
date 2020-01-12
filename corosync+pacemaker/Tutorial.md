
# Configuring Corosync
1. You need to generate a shared secret for the corosync instances on all of the nodes in your cluster. On one of the nodes execute "corosync-keygen", which will generate the file "/etc/corosync/authkey".
2. Configure the corosync instances. Since we would run each cluster in separate bridge, you can safely use multicast, but you can also use unicast, for situations like the network in GCP.
```
totem {
        nodeid: 1
        version: 2
        hold:  190
        token: 310  	    # How long before declaring a token lost (ms)
        token_retransmits_before_loss_const: 10		# How many token retransmits before forming a new configuration
        join: 5000      	# How long to wait for join messages in the membership protocol (ms)
        consensus: 7500 	# How long to wait for consensus to be achieved before starting a new round of membership configuration (ms)
        vsftype: none   	# Turn off the virtual synchrony filter
        max_messages: 20	# Number of messages that may be sent by one processor on receipt of the token
        secauth: on     	# Enable encryption
        threads: 1      	# How many threads to use for encryption/decryption
        clear_node_high_bit: yes	# Limit generated nodeids to 31-bits (positive signed integers)
        rrp_mode: passive
        interface {
                ttl: 1
                transport: udpu
                ringnumber: 0
                bindnetaddr: 10.0.0.1
				mcastport: 5405
                mcastaddr: 239.255.42.1
                member {
                        memberaddr: 10.0.0.1
                }
                member {
                        memberaddr: 10.0.0.2
                }
                member {
                        memberaddr: 10.0.0.3
                }
        }
}

nodelist {
        node {
                ring0_addr: 10.0.0.1
                nodeid: 1
        }
        node {
                ring0_addr: 10.0.0.2
                nodeid: 2
        }
        node {
                ring0_addr: 10.0.0.5
                nodeid: 3
        }
}

logging {
        fileline: off
        to_syslog: yes
        to_stderr: no
        syslog_facility: daemon
        debug: off
        timestamp: on
}
amf {
        mode: disabled
}
```
Important part of the above configuration is the node list, which should list all possible nodes in the cluster. Also in the "totem { }" section you MUST specify different node ids.
3. Add the pacemaker service in "/etc/corosync/service.d/"
```
service {
        # Load the Pacemaker Cluster Resource Manager
        name: pacemaker
        ver: 0
}
```
4. Since the corosync configuration should be the same on all nodes in the cluster, you should sync /etc/corosync to the other two nodes in the cluster.
!!! Except the nodeid in the "totem { }" section of corosync.conf. That MUST be unique.
5. Start the corosync service:
   /etc/init.d/corosync start

Corosync should also start pacemaker, which will start a few other processes that are used to manage the servers.

# Configuring Pacemaker
This is relatively easy with crmsh. You have all the needed configurations in each folder, for each service.

Now as corosync has started pacemaker you can configure your cluster with the crm command:
```
  # crm configure
  crm(live)configure#
```
In this prompt you can paste the per-service crm configrations that I have provided below:
* [Nginx](../nginx/Corosync+Pacemaker.md)
* [HAproxy](../haproxy/Corosync+Pacemaker.md)
* [ProxySQL](../proxysql/Corosync+Pacemaker.md)
* [Redis](../redis/Corosync+Pacemaker.md)

The only two global properties you need to setup are:
* disable the Shoot The Other Node In The Head option, that will try to shutdown other nodes in case of split brain
```
  crm(live)configure# property stonith-enabled=false
```
* disable maintenance mode. In fact, when you setup your cluster for the first time, this property will be missing, we are adding it here, so once we need to put the whole clsuter in maintenance mode, we don't need to remember the name of the property
```
  crm(live)configure# property maintenance-mode=false
```

Finally when you have added all of your configuration, you can list it by issuing the "show" command:
```
  crm(live)configure# show
  node node1
  node node2
  node node3
  property cib-bootstrap-options: \
        have-watchdog=false \
        dc-version=1.1.18-3.el6-bfe4e80420 \
        cluster-infrastructure="classic openais (with plugin)" \
        expected-quorum-votes=3 \
        stonith-enabled=false \
        maintenance-mode=false \
        no-quorum-policy=ignore \
        last-lrm-refresh=1578852361
```

If everything is fine, ask the pacemaker to check your configuration by issuing the "verify" command:
```
  crm(live)configure# verify
  crm(live)configure#
```
If there are no errors, now you can commit your changes to the cluster:
```
  crm(live)configure# commit
```

Congratulations you have successfully configured your corosync and pacemaker.

You can easily vew the current status by issuing any of these shell commands:
```
  # crm status
  # crm_mond -Arf
```

In this directory, there are also two files ocf:heartbeat:mysql and ocf:heartbeat:redis, which are modified versions of the original OCF scripts, which better support for MySQL and Redis failover. You should copy those to "/usr/lib/ocf/resource.d/heartbeat/".

# Adding a floating IP
In crm shell configration enter the following lines:
```
  # crm configure
```

```
primitive ip-130 IPaddr2 \
        params ip=85.14.7.130 cidr_netmask=26 nic=eth0 \
        op monitor interval=10s \
        meta target-role=Started
```
* ip-130 is the name of the resouce
* IPaddr2 is the ocf script that will be used for this IP. It will do arping, when it moves an IP address to a new machine
* "op monitor interval=10s", means that every 10s pacemaker will check if the IP is still UP on the machine it last brought it up
* from the params, nic is the interface on which, this IP should be configured

If you want this IP to stay on specific node, add a location constraint like this one:
```
location ip-130-on-node1 ip-130 inf: node1
```
Or if you want this IP not to go on specific node:
```
location ip-130-not-on-node1 ip-130 -inf: node1
```
If you want the IP to go, where a specific Master-Slave resource is Master, you need the following co-location constraint:
```
colocation ip-130-with-mysql-master inf: ip-130 ms_mysql:Master
```
If you want the IP to go, where a specific resource is started, you can use the following co-location constraint:
```
colocation ip-130-with-nginx inf: ip-130 nginx
```
Where "nginx" is the name of the resource.

