---
layout: post
title: Apache Maven - 创建Maven脚手架模板
---

创建Maven脚手架，快速创建 Spring Boot 项目。

---

[1] 创建脚手架模板。

{% highlight shell %}
X:\dev> mvn archetype:generate -DgroupId=net.mingyang ^
            -DartifactId=spring-boot-quickstart ^
            -DarchetypeArtifactId=maven-archetype-quickstart ^
            -DinteractiveMode=false ^
            -DarchetypeCatalog=local
{% endhighlight %}

pom.xml:

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.mingyang</groupId>
    <artifactId>spring-boot-quickstart</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>spring-boot-quickstart</name>
    <url>http://maven.apache.org</url>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.4.1.RELEASE</version>
        <relativePath />
    </parent>

      <dependencies>
            <dependency>
                  <groupId>org.springframework.boot</groupId>
                  <artifactId>spring-boot-starter</artifactId>
            </dependency>
      </dependencies>
</project>
{% endhighlight %}

src/main/java/net/mingyang/spring_boot_quickstart/Application.java:

{% highlight java %}
package net.mingyang.spring_boot_quickstart;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.context.annotation.Bean;

public class Application 
{
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Value("${welcome.message}")
    private String welcomeMessage;
    
    @Bean
      public ApplicationRunner runner() {
            return new ApplicationRunner() {
                  public void run(ApplicationArguments args) throws Exception {
                        System.out.println(welcomeMessage);
                  }
            };
      }
}
{% endhighlight %}

src/main/resources/application.properties:

{% highlight properties %}
welcome.message=Hello World!
{% endhighlight %}

---

[2] 生成脚手架模板。 

{% highlight shell %}
X:\dev> cd spring-boot-quickstart

X:\dev\spring-boot-quickstart> mvn archetype:create-from-project
{% endhighlight %}

Maven 使用 **archetype:create-from-project** 在 **target\generated-sources\archetype** 目录下生成脚手架模板。

这里的mvn是对 **spring-boot-quickstart** 目录操作。

---

[3] 查看模板描述文件。 

**archetype\src\main\resources\META-INF\maven\archetype-metadata.xml** 是模板描述文件，说明了如何生成新项目。

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<archetype-descriptor xsi:schemaLocation="http://maven.apache.org/plugins/maven-archetype-plugin/archetype-descriptor/1.0.0 http://maven.apache.org/xsd/archetype-descriptor-1.0.0.xsd" name="spring-boot-quickstart"
    xmlns="http://maven.apache.org/plugins/maven-archetype-plugin/archetype-descriptor/1.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <fileSets>
    <fileSet filtered="true" packaged="true" encoding="UTF-8">
      <directory>src/main/java</directory>
      <includes>
        <include>**/*.java</include>
      </includes>
    </fileSet>
    <fileSet filtered="true" encoding="UTF-8">
      <directory>src/main/resources</directory>
      <includes>
        <include>**/*.properties</include>
      </includes>
    </fileSet>
  </fileSets>
</archetype-descriptor>
{% endhighlight %}

Archetype的一些built-in参数：

<table cellpadding="12" cellspacing="10" border="1">
  <tr>
    <th>Variable</th>
    <th>Meaning</th>
  </tr>
  <tr><td>__rootArtifactId__</td><td>做文件夹名替换用，例如__rootArtifactId__-dal</td></tr>
  <tr><td>${rootArtifactId}</td><td>Already explained above, it holds the value entered by the user as the project name (the value that maven ask as the artifactId: in the prompt when the user runs the archetype)</td></tr>
  <tr><td>${artifactId}</td><td>If your project is composed by one module, this variable will have the same value as ${rootArtifactId}, but if the project contains several modules, this variable will be replaced by the module name inside every module folder, for example: given a module named portlet-domain inside a project namedportlet, all the files inside this module folder that are to be filtered will have the value of the variable ${artifactId} replaced by portlet-domainwhereas the ${rootArtifactId} variable will be replaced by portlet</td></tr>
  <tr><td>${package}</td><td>The user provided package for the project, also prompted by maven when the user runs the archetype</td></tr>
  <tr><td>${packageInPathFormat}</td><td>The same value as ${package} variable but replacing '.' with the character'/', e.g:, for the package com.foo.bar this variable is com/foo/bar</td></tr>
  <tr><td>${groupId}</td><td>The user supplied groupId for the project, prompted by maven when the user runs the archetype</td></tr>
  <tr><td>${version}</td><td>The user supplied version for the project, prompted by maven when the user runs the archetype</td></tr>
</table>

---

参考：

[Maven Archetype Descriptor Model  ](http://maven.apache.org/archetype/archetype-models/archetype-descriptor/archetype-descriptor.html)

[How is metadata about an archetype stored?](http://maven.apache.org/archetype/maven-archetype-plugin/specification/archetype-metadata.html)

---

[4] 查看脚手架文件。 

archetype\src\main\resources\archetype-resources\pom.xml:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
      <modelVersion>4.0.0</modelVersion>

      <groupId>${groupId}</groupId>
      <artifactId>${artifactId}</artifactId>
      <version>${version}</version>
      <packaging>jar</packaging>

      <name>${artifactId}</name>
      <url>http://maven.apache.org</url>

      <properties>
            <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
      </properties>

      <parent>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-parent</artifactId>
            <version>1.4.1.RELEASE</version>
      </parent>

      <dependencies>
            <dependency>
                  <groupId>org.springframework.boot</groupId>
                  <artifactId>spring-boot-starter</artifactId>
            </dependency>
      </dependencies>
</project>
{% endhighlight %}

archetype\src\main\resources\archetype-resources\src\main\java\Application.java:

{% highlight java %}
#set( $symbol_pound = '#' )
#set( $symbol_dollar = '$' )
#set( $symbol_escape = '\' )
package ${package};

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.context.annotation.Bean;

public class Application 
{
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Value("${symbol_dollar}{welcome.message}")
    private String welcomeMessage;
    
    @Bean
      public ApplicationRunner runner() {
            return new ApplicationRunner() {
                  public void run(ApplicationArguments args) throws Exception {
                        System.out.println(welcomeMessage);
                  }
            };
      }
}
{% endhighlight %}

archetype\src\main\resources\archetype-resources\src\main\resources\application.properties:

{% highlight properties %}
#set( $symbol_pound = '#' )
#set( $symbol_dollar = '$' )
#set( $symbol_escape = '\' )
welcome.message=Hello World!
{% endhighlight %}

---

[5] 安装脚手架模板。

{% highlight shell %}
X:\dev\spring-boot-quickstart> target\generated-sources\archetype 

X:\dev\spring-boot-quickstart\target\generated-sources\archetype> mvn install
{% endhighlight %}

这里的mvn是对 **archetype** 目录操作。

---

[6] 使用新模板创建新项目。

{% highlight shell %}
X:\dev> mvn archetype:generate -DgroupId=net.mingyang ^
            -DartifactId=spring-boot-helloworld ^
            -Dpackage=net.mingyang.spring_boot_helloworld ^
            -DarchetypeGroupId=net.mingyang ^
            -DarchetypeArtifactId=spring-boot-quickstart-archetype ^
            -DinteractiveMode=false ^
            -DarchetypeCatalog=local
{% endhighlight %}

注意这里的脚手架Id默认会带一个 **-archetype** 结尾。

**package** 参数最好能够指定，默认是与 **groupId** 相同。**artifactId** 不能作为包名，因为 **artifactId** 会包含一些特殊符号，这是Java不允许的。