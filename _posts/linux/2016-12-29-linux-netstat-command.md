---
layout: post
title: 查找端口
---

列出所有端口：

{% highlight shell %}
[root@localhost ~]# netstat -ntlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1456/sshd           
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      1745/master         
tcp6       0      0 :::22                   :::*                    LISTEN      1456/sshd           
tcp6       0      0 ::1:25                  :::*                    LISTEN      1745/master 
{% endhighlight %}