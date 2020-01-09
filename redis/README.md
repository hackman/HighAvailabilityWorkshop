Redis replication is straight forward, you only need to set the following option:

 slaveof 172.16.31.74 6379

If you want to prevent Redis from connecting to the wrong redis instance, you can set in your redis.conf: 
 slaveof 0.0.0.0 6379

This way every time Redis is started it will think it is a Master resource. 

However, if you run Redis like this, you risk to have a situation where two servers can be master at the same time.

To prevent such situations, we need to have some control over which server is slave and which one is master.

This can be done via different ways. We will discuss two possible solutions, Corosync + Pacemaker and Sentinel.

If you want to use Corosync + Pacemaker for cluster management, then look at the Corosync+Pacemaker.md

If you want to use Sentinel for cluster management, look at Sentinel.md
