---
layout: post
title: 系统进程
---

{% highlight shell %}
[root@localhost ~]# ps aux
USER        PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
polkitd     967  0.0  1.3 523520 13764 ?        Ssl  09:22   0:00 /usr/lib/polkit-1/polkitd --no-debug
root        969  0.0  0.2  53056  2664 ?        Ss   09:22   0:00 /usr/sbin/wpa_supplicant -u -f /var/log/wpa_supplic
root       1455  0.0  1.6 553060 16296 ?        Ssl  09:22   0:00 /usr/bin/python -Es /usr/sbin/tuned -l -P
root       1456  0.0  0.3  82544  3580 ?        Ss   09:22   0:00 /usr/sbin/sshd -D
root       1745  0.0  0.2  91124  2076 ?        Ss   09:22   0:00 /usr/libexec/postfix/master -w
postfix    1751  0.0  0.3  91228  3880 ?        S    09:22   0:00 pickup -l -t unix -u
postfix    1752  0.0  0.3  91296  3904 ?        S    09:22   0:00 qmgr -l -t unix -u
root       2601  0.0  0.2  90208  2404 ?        Ss   09:22   0:00 login -- root
root       2608  0.0  0.2 115372  2012 tty1     Ss+  09:22   0:00 -bash
root       2635  0.0  0.5 140772  5092 ?        Ss   09:32   0:00 sshd: root@pts/0
root       2639  0.0  0.1 115376  1988 pts/0    Ss+  09:33   0:00 -bash
root       2695  0.0  0.0      0     0 ?        S<   09:52   0:00 [kworker/0:2H]
root       2713  0.0  0.0      0     0 ?        S<   10:00   0:00 [kworker/0:0H]
root       2725  0.0  0.0 123304   748 ?        Ss   10:01   0:00 /usr/sbin/anacron -s
root       2735  0.0  0.0      0     0 ?        S    10:07   0:00 [kworker/0:0]
root       2826  0.0  1.5 110508 15800 ?        S    10:08   0:00 /sbin/dhclient -d -q -sf /usr/libexec/nm-dhcp-helpe
root       2844  0.0  0.0      0     0 ?        S<   10:10   0:00 [kworker/0:1H]
root       2845  0.0  0.0      0     0 ?        S    10:12   0:00 [kworker/0:1]
root       2846  0.0  0.5 140772  5092 ?        Ss   10:13   0:00 sshd: root@pts/1
{% endhighlight %}

---

<p style="margin-bottom: 0px;">各列的含义：</p>
<pre>
USER    用户名 
%CPU    进程占用的CPU百分比 
%MEM    占用内存的百分比 
VSZ     该进程使用的虚拟內存量（KB） 
RSS     该进程占用的固定內存量（KB）（驻留中页的数量） 
STAT    进程的状态 
START   该进程被触发启动时间 
TIME    该进程实际使用CPU运行的时间
</pre>

---
<p style="margin-bottom: 0px;">其中STAT状态位常见的状态字符：</p>
<pre>
D       无法中断的休眠状态（通常 IO 的进程）
R       正在运行可中在队列中可过行的 
S       处于休眠状态 
T       停止或被追踪
W       进入内存交换 （从内核2.6开始无效）
X       死掉的进程（基本很少见）
Z       僵尸进程
<       优先级高的进程 
N       优先级较低的进程 
L       有些页被锁进内存
s       进程的领导者（在它之下有子进程）
l       多线程，克隆线程（使用 CLONE_THREAD, 类似 NPTL pthreads）
+       位于后台的进程组
<pre>