---
layout: post
title: IP地址
---

{% highlight shell %}
[root@localhost ~]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eno16777736: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:9c:3d:cb brd ff:ff:ff:ff:ff:ff
    inet 192.168.154.133/24 brd 192.168.154.255 scope global dynamic eno16777736
       valid_lft 1136sec preferred_lft 1136sec
    inet6 fe80::20c:29ff:fe9c:3dcb/64 scope link 
       valid_lft forever preferred_lft forever
{% endhighlight %}