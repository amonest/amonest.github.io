---
layout: post
title: 查找文件
---

根据名称查找文件：

{% highlight shell %}
[root@localhost ~]# find / -name redis
/run/redis
/etc/systemd/system/redis-sentinel.service.d
/etc/systemd/system/redis.service.d
/etc/selinux/targeted/modules/active/modules/redis.pp
/etc/logrotate.d/redis
/etc/redis-sentinel.conf
/etc/redis.conf
/var/lib/redis
/var/log/redis
/usr/bin/redis-check-dump
/usr/bin/redis-cli
/usr/bin/redis-benchmark
/usr/bin/redis-sentinel
/usr/bin/redis-server
/usr/bin/redis-shutdown
/usr/bin/redis-check-aof
/usr/lib/systemd/system/redis.service
/usr/lib/systemd/system/redis-sentinel.service
/usr/lib/tmpfiles.d/redis.conf
/usr/share/doc/redis-2.8.19
/usr/share/licenses/redis-2.8.19
{% endhighlight %}