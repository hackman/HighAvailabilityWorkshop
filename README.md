This workshop will start with you, receiving the 3 IPs of your containers.
On each container you will have preinstalled the following software:
- Nginx
- uWSGI
- Wordpress in user wpsite
- Percona MySQL 5.7
- Corosync + Pacemaker + crmsh
- ProxySQL 
- HAproxy
- Redis
- Redis-Sentinel
You will also receive 2 public, floating IPs for your site and 2 private IPs for your MySQL and Redis installations.
Nginx, uWSGI and Wordpress are already preconfigured to work with the MySQL and Redis on lxc1.

The setup will look like this:
- lxc1(web and db node)
- lxc2(web and db node)
- lxc3 (standby/failover node)

I hope that by the end of the day we would have this setup:

    Public IP 1 --> lxc1 -> Nginx -> uWSGI(unix socket) --\
                                                          |- HAproxy (127.0.0.1) -> lxc? -> Redis			
                                                          \- ProxySQL(172.0.0.1) -> lxc? -> MySQL
    
    Public IP 2 --> lxc2 -> Nginx -> uWSGI(unix socket) --\
                                                          |- HAproxy (127.0.0.1) -> lxc? -> Redis			
                                                          \- ProxySQL(172.0.0.1) -> lxc? -> MySQL

 In the above setup, "lxc?" means, the container, which is currently hosting the Master resource of the specific service(MySQL or Redis).


But we should start with a simpler setup:

    Public IP 1 --> lxc1 -> Nginx -> uWSGI(unix socket) --\
                                                          |- Redis	private floating IP
                                                          |- MySQL private loating IP
    Public IP 2 --> lxc2 -> Nginx -> uWSGI(unix socket) --/

What you don't see on the above diagrams is corosync and pacemaker. They are used to check the status of the nodes and take actions, in case one of the nodes dies.
This includes, move the IP to another, online machine. Demote and promote master-slave resources.
Also you have to know, that both HAproxy and ProxySQL have connections to all 3 instances of Redis and MySQL and they are responsible for directing the traffic to the correct backend server.

So the tasks are:
1. [Setup Redis replication with master lxc1 and slaves lxc2 and lxc3](../redis/README.md)
2. [Setup MySQL replication with master lxc1 and slaves lxc2 and lxc3](../mysql/README.md)
3. [Setup Pacemaker](../corosync+pacemaker/Tutorial.md)
3.1. [Add the two public IPs and add constraint for them, not to run on the same node.](../corosync+pacemaker/Tutorial.md#adding-a-floating-ip)
3.2. [Configure master-slave resource for the Redis service](../redis/Corosync+Pacemaker.md)
3.3. [Add a private floating IP that will go with the Master Redis resouce](../corosync+pacemaker/Tutorial.md#adding-a-floating-ip)
3.4. [Configure master-slave resource for the MySQL service](../mysql/Corosync+Pacemaker.md)
3.5. [Add a private floating IP that will go with the Master MySQL resouce](../corosync+pacemaker/Tutorial.md#adding-a-floating-ip)
4. Make sure cron tasks for the wpsite run only on a single machine in the cluster

After all of the above works, test the setup and also migrate the IPs and master-slave resouces, to test the failover.



Next if all of the above works, we should setup HAproxy, Sentinel and ProxySQL.

But first. Why would we need those if the above setup works?
- at GCP and other cloud providers you can't float IPs with pacemaker, simply because the public IPs are not on your VMs
- even thou the above mentioned providers, provide you with alternatives, usually those are slower then what you can achive with Corosync+Pacemaker
- ProxySQL allows you to make read/write split and load balancing of queries

If you want fast failover, you can't use GCP floating as it requires at least 10sec with the fastests health checks.



So the next tasks are:

5. Configure ProxySQL on each web node
5.1. create a monitor user for the proxysql in the MySQL
5.2. start the proxysql instance
5.3. configure it via the SQL interface
5.4. add aliases for the admin interface
6. Configure HAproxy on each web node
7. Configure Sentinel on each web node

Verify both Redis and MySQL

Alternatives to ProxySQL are Vitess, MaxScale and MySQL Router.



In this workshop, we are not going to discuss Shared storage options. You have to know, that uploading your application (in our case Wordpress) should deploy all neccessery files for the app.
However, most of the time, the apps work with user supplied files, and if you allow uploads, you should make sure that the uploads are available on all web nodes.
This usually is achived by using a shared storage, which can be(but not limited to) any of the following options:
- NFS exported folder from one of the nodes
- GlusterFS/BeeGFS/MooseFS
- Amazon S3/GCP Cloud Storage
- DRBD + OCFS2

