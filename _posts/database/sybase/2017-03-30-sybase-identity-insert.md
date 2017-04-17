---
layout: post
title: Sybase - 插入identity数据
---

Sybase标识列identity有时会出现500000X这样问题。

对于资料比较少的数据表可以这样处理：

[1] 将有问题的数据表资料导出为TEXT文件，然后修正TEXT资料。

[2] 新增数据表，结构和旧表一样，不需要数据。

[3] 开启identity_insert。

{% highlight sql %}
set identity_insert table_name on
{% endhighlight %}

[4] 将TEXT资料导入新表。

[5] 关闭identity_insert。

{% highlight sql %}
set identity_insert table_name off
{% endhighlight %}