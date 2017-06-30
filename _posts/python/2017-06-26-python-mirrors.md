---
layout: post
title: Pip国内镜像
---

阿里云 <http://mirrors.aliyun.com/pypi/simple/>

中国科技大学 <https://pypi.mirrors.ustc.edu.cn/simple/>

豆瓣(douban) <http://pypi.douban.com/simple/> 

清华大学 <https://pypi.tuna.tsinghua.edu.cn/simple/>

中国科学技术大学 <http://pypi.mirrors.ustc.edu.cn/simple/>


使用方法很简单，直接 -i 加 url 即可！

{% highlight shell %}
＃　pip install web.py -i http://pypi.douban.com/simple
{% endhighlight %}

或者

{% highlight shell %}
# pip install web.py -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
{% endhighlight %}

 
如果想配置成默认的源，需要创建或修改配置文件（一般都是创建），

linux的文件在~/.pip/pip.conf，windows在%HOMEPATH%\pip\pip.ini）。

修改内容为：

{% highlight shell %}
[global]
index-url = http://pypi.douban.com/simple
[install]
trusted-host = pypi.douban.com
{% endhighlight %}
 
这样在使用pip来安装时，会默认调用该镜像。







To install pip, securely download [get-pip.py](https://bootstrap.pypa.io/get-pip.py).
