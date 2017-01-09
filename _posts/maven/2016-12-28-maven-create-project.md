---
layout: post
title: Apache Maven - 缓存ArchetypeCatalog
---

Maven使用 **archetype:generate** 创建新项目：

{% highlight shell %}
X:\dev> mvn archetype:generate -DgroupId=net.mingyang ^
            -DartifactId=spring-boot-config ^
            -DarchetypeArtifactId=maven-archetype-quickstart ^
            -DinteractiveMode=false
[INFO] Scanning for projects...
[INFO]
[INFO] Using the builder org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder with a thread count of 1
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] Building Maven Stub Project (No POM) 1
[INFO] ------------------------------------------------------------------------
[INFO]
[INFO] >>> maven-archetype-plugin:2.4:generate (default-cli) @ standalone-pom >>>
[INFO]
[INFO] <<< maven-archetype-plugin:2.4:generate (default-cli) @ standalone-pom <<<
[INFO]
[INFO] --- maven-archetype-plugin:2.4:generate (default-cli) @ standalone-pom ---
[INFO] Generating project in Batch mode
{% endhighlight %}

多数会卡在这里很长时间没有反应。使用 **-debug** 查看：

{% highlight shell %}
X:\dev> mvn archetype:generate -DgroupId=net.mingyang ^
            -DartifactId=spring-boot-config ^
            -DarchetypeArtifactId=maven-archetype-quickstart ^
            -DinteractiveMode=false ^
            -debug
[INFO] Generating project in Batch mode
[DEBUG] Searching for remote catalog: http://repo.maven.apache.org/maven2/archetype-catalog.xml
{% endhighlight %}

发行原因是Maven要读取 **http://repo1.maven.org/maven2/archetype-catalog.xml** 这个文件。

可以将这个文件下载到本地，放在Maven仓库所在目录，避免每次重复下载。

{% highlight shell %}
X:\dev> curl http://repo1.maven.org/maven2/archetype-catalog.xml > X:\bin\apache-maven-3.2.1\repo\archetype-catalog.xml
{% endhighlight %}

重新执行 **archetype:generate**：

{% highlight shell %}
X:\dev> mvn archetype:generate -DgroupId=net.mingyang ^
            -DartifactId=spring-boot-config ^
            -DarchetypeArtifactId=maven-archetype-quickstart ^
            -DinteractiveMode=false ^
            -DarchetypeCatalog=local
{% endhighlight %}

转换成Eclipse项目：

{% highlight shell %}
X:\dev\spring-boot-config> mvn eclipse:eclipse
{% endhighlight %}