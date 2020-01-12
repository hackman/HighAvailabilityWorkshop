
# Configuring Corosync
1. You need to generate a shared secret for the corosync instances on all of the nodes in your cluster. On one of the nodes execute "corosync-keygen", which will generate the file "/etc/corosync/authkey".
2. Configure the corosync instances. Since we would run each cluster in separate bridge, you can safely use multicast, but you can also use unicast, for situations like the network in GCP.
```
totem {
        nodeid: 1358
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
                nodeid: 1358
        }
        node {
                ring0_addr: 10.0.0.2
                nodeid: 1359
        }
        node {
                ring0_addr: 10.0.0.5
                nodeid: 1360
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
3. Add the pacemaker service in "/etc/corosync/service.d/"
```
service {
        # Load the Pacemaker Cluster Resource Manager
        name: pacemaker
        ver: 0
}
```
4. Since the corosync configuration should be the same on all nodes in the cluster, you should sync /etc/corosync to the other two nodes in the cluster.

# Configuring Pacemaker
This is relatively easy with crmsh. You have all the needed configurations in each folder, for each service.

* [Nginx](../nginx/Corosync+Pacemaker.md)
* [HAproxy](../haproxy/Corosync+Pacemaker.md)
* [ProxySQL](../proxysql/Corosync+Pacemaker.md)
* [Redis](../redis/Corosync+Pacemaker.md)

