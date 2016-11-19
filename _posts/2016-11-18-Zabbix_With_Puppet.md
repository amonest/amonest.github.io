---
layout: post
title: 用Puppet推送Zabbix Agent
---

[1] 创建zabbix模块目录。

{% highlight shell %}
$ mkdir -p /etc/puppet/modules/zabbix/{manifests,templates}
{% endhighlight %}

---


[2] 创建init.pp清单：

{% highlight shell %}
$ cat /etc/puppet/modules/zabbix/manifests/init.pp 
class zabbix {
  package { 'epel-release':
    ensure => installed,
  }
  package { 'zabbix22-agent':
    ensure => installed,
  }
  file { '/etc/zabbix/zabbix_agentd.conf':
    content => template("zabbix/zabbix_agentd.conf.erb"),
    ensure => file,
  }
  service { 'zabbix-agent':
    ensure => "running",
    hasstatus => true,
    enable => true,
  }
  Package["zabbix22-agent"] -> File["/etc/zabbix/zabbix_agentd.conf"] -> Service["zabbix-agent"]
}
{% endhighlight %}

---


[3] 创建zabbix_agentd.conf.erb模板：

{% highlight shell %}
$ cp /etc/zabbix/zabbix_agentd.conf /etc/puppet/modules/zabbix/templates/zabbix_agentd.conf.erb

$ cat /etc/puppet/modules/zabbix/templates/zabbix_agentd.conf.erb
Server=<%= zabbix_server %>
ServerActive=<%= zabbix_server %>
Hostname=<%= fqdn %>
... ... ... ...
{% endhighlight %}

---


[4] 编辑site.pp：
{% highlight shell %}
$# cat /etc/puppet/manifests/site.pp 
Package {
  allow_virtual => true,
}

node default {
  $zabbix_server = "192.168.154.137"
  include zabbix
}
{% endhighlight %}

