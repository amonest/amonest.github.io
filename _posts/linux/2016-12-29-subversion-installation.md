---
layout: post
title: 安装Subversion
---

[1] 安装Subversion：

{% highlight shell %}
[root@localhost ~]# yum install subversion
{% endhighlight %}

仓库默认目录是 **/var/svn**，可以通过 **/etc/sysconfig/svnserve** 修改。

---

[2] 创建仓库：

{% highlight shell %}
[root@localhost ~]# mkdir -p /var/svn

[root@localhost ~]# svnadmin create /var/svn/spring-hello-world

[root@localhost ~]# ll /var/svn/spring-hello-world/
total 16
drwxr-xr-x. 2 root root   51 Dec 29 22:14 conf
drwxr-sr-x. 6 root root 4096 Dec 29 22:14 db
-r--r--r--. 1 root root    2 Dec 29 22:14 format
drwxr-xr-x. 2 root root 4096 Dec 29 22:14 hooks
drwxr-xr-x. 2 root root   39 Dec 29 22:14 locks
-rw-r--r--. 1 root root  229 Dec 29 22:14 README.txt
{% endhighlight %}

---

[3] 配置仓库。

{% highlight shell %}
[root@localhost ~]# cat /var/svn/spring-hello-w/conf/passwd 
[users]
user1 = pass1  #用户1
user2 = pass2  #用户2
user3 = pass3  #用户3

[root@localhost ~]# cat /var/svn/spring-hello-w/conf/authz 
[/]
user1 = rw #读写权限
user2 = r  #只读权限
user3 =    #无权限

[root@localhost ~]# cat /var/svn/spring-hello-w/conf/svnserve.conf 
### This file controls the configuration of the svnserve daemon, if you
### use it to allow access to this repository.  (If you only allow
### access through http: and/or file: URLs, then this file is
### irrelevant.)

### Visit http://subversion.apache.org/ for more information.

[general]
### The anon-access and auth-access options control access to the
### repository for unauthenticated (a.k.a. anonymous) users and
### authenticated users, respectively.
### Valid values are "write", "read", and "none".
### Setting the value to "none" prohibits both reading and writing;
### "read" allows read-only access, and "write" allows complete 
### read/write access to the repository.
### The sample settings below are the defaults and specify that anonymous
### users have read-only access to the repository, while authenticated
### users have read and write access to the repository.
anon-access = none   #匿名用户不能访问
auth-access = write  #授权用户可读写

### The password-db option controls the location of the password
### database file.  Unless you specify a path starting with a /,
### the file's location is relative to the directory containing
### this configuration file.
### If SASL is enabled (see below), this file will NOT be used.
### Uncomment the line below to use the default password file.
password-db = passwd #用户文件

### The authz-db option controls the location of the authorization
### rules for path-based access control.  Unless you specify a path
### starting with a /, the file's location is relative to the the
### directory containing this file.  If you don't specify an
### authz-db, no path-based access control is done.
### Uncomment the line below to use the default authorization file.
authz-db = authz     #授权文件

### This option specifies the authentication realm of the repository.
### If two repositories have the same authentication realm, they should
### have the same password database, and vice versa.  The default realm
### is repository's uuid.
realm = spring-hello-world
{% endhighlight %}

---

[4] 配置防火墙。

{% highlight shell %}
[root@localhost ~]# firewall-cmd --add-port=3690/tcp --permanent

[root@localhost ~]# firewall-cmd --reload

[root@localhost ~]# firewall-cmd --list-all
public (default, active)
  interfaces: eno16777736
  sources: 
  services: dhcpv6-client ssh
  ports: 3690/tcp
  masquerade: no
  forward-ports: 
  icmp-blocks: 
  rich rules: 
{% endhighlight %}

---

[5] 关闭SELinux。

{% highlight shell %}
[root@localhost ~]# setenforce 0
{% endhighlight %}

---

[6] 启动服务。

{% highlight shell %}
[root@localhost ~]# systemctl enable svnserve.service

[root@localhost ~]# systemctl start svnserve.service
{% endhighlight %}

---

[6] 客户端测试。

{% highlight shell %}
[root@localhost ~]# svn checkout --username user1 svn://localhost/spring-hello-world
A    spring-hello-world/tags
A    spring-hello-world/trunk
A    spring-hello-world/trunk/LICENSE.txt
A    spring-hello-world/trunk/index.html
A    spring-hello-world/trunk/README.txt
A    spring-hello-world/branches
Checked out revision 4.

[root@localhost ~]# cd spring-hello-world

[root@localhost spring-hello-world]# touch index.php

[root@localhost spring-hello-world]# svn add index.php
A         index.php

[root@localhost spring-hello-world]# svn commit --username user1 -m "index"
Adding         index.php
Transmitting file data .
Committed revision 5.
{% endhighlight %}