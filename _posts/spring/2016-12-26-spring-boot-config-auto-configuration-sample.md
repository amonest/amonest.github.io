---
layout: post
title: 自动配置实例
---

目的：有一个接口 **HelloService**，当应用程序没有配置对应的Bean时，使用自动配置的 **StandardHelloServer**。**StandardHelloServer** 可以使用 **application.properties** 配置文字。

---

[1] 参考[《@EnableAutoConfiguration》](/2016/12/26/spring-boot-test-enable-auto-configuration)。

---

[2] 创建Maven项目。

---

[3] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.mingyang</groupId>
    <artifactId>spring-boot-test</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>spring-boot-test</name>
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

---

[3] src/main/java/net/mingyang/spring_boot_test/HelloService.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

public class HelloService {
   private String text;
   
   public HelloService() {
      super();
   }

   public HelloService(String text) {
      super();
      this.text = text;
   }

   public String getText() {
      return text;
   }

   public void setText(String text) {
      this.text = text;
   }
}
{% endhighlight %}

---

[4] src/main/java/net/mingyang/spring_boot_test/HelloServiceProperties.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("hello")
public class HelloServiceProperties {
   
   private static final String DEFAULT_TEXT = "default";
   
   private String text = DEFAULT_TEXT;
   
   public String getText() {
      return text;
   }

   public void setText(String text) {
      this.text = text;
   }
}
{% endhighlight %}

---

[6] src/main/java/net/mingyang/spring_boot_test/HelloServiceAutoConfiguration.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(HelloServiceProperties.class)
@ConditionalOnClass(HelloService.class)
public class HelloServiceAutoConfiguration {
   
   @Autowired
   private HelloServiceProperties helloServiceProperties;
   
   @Bean
   @ConditionalOnMissingBean(HelloService.class)
   public HelloService helloService() {
      HelloService helloService = new HelloService();
      helloService.setText(helloServiceProperties.getText());
      return helloService;
   }
}
{% endhighlight %}

---

[7] src/main/resources/META-INF/spring.factories:

{% highlight ini %}
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
net.mingyang.spring_boot_test.HelloServiceAutoConfiguration
{% endhighlight %}

---

[8] Install:

{% highlight shell %}
D:\dev\spring-boot-test> mvn install
{% endhighlight %}

---

[9] 创建测试项目，pom.xml:

{% highlight xml %}
<dependency>
   <groupId>org.springframework.boot</groupId>
   <artifactId>spring-boot-starter</artifactId>
</dependency>

<dependency>
   <groupId>net.mingyang</groupId>
   <artifactId>spring-boot-test</artifactId>
   <version>0.0.1-SNAPSHOT</version>
</dependency>
{% endhighlight %}

---

[10] 测试一，不做任何配置。

src/main/java/net/mingyang/spring-boot-auto-config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_auto_config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import net.mingyang.spring_boot_test.HelloService;

@SpringBootApplication
public class Application {
   
   public static void main(String[] args) {
      SpringApplication.run(Application.class, args);
   }
   
   @Autowired
   HelloService helloService;
   
   @Bean
   public ApplicationRunner runner() {
      return new ApplicationRunner() {
         public void run(ApplicationArguments args) throws Exception {
            System.out.println("Text: " + helloService.getText());
         }
      };
   }
}
{% endhighlight %}

Run:

{% highlight shell %}
D:\dev\spring-boot-auto-config> mvn spring-boot:run
Text: default
{% endhighlight %}

这里的HelloService Bean来源于HelloServiceAutoConfiguration，文字来源于HelloServiceProperties。

---

[11] 测试二，配置application.properties。

src/main/java/net/mingyang/spring-boot-auto-config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_auto_config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import net.mingyang.spring_boot_test.HelloService;

@SpringBootApplication
public class Application {
   
   public static void main(String[] args) {
      SpringApplication.run(Application.class, args);
   }
   
   @Autowired
   HelloService helloService;
   
   @Bean
   public ApplicationRunner runner() {
      return new ApplicationRunner() {
         public void run(ApplicationArguments args) throws Exception {
            System.out.println("Text: " + helloService.getText());
         }
      };
   }
}
{% endhighlight %}

src/main/resources/application.properties:

{% highlight properties %}
hello.text = application.properties
{% endhighlight %}

Run:

{% highlight shell %}
D:\dev\spring-boot-auto-config> mvn spring-boot:run
Text: application.properties
{% endhighlight %}

这里的HelloService Bean来源于HelloServiceAutoConfiguration，文字来源于application.properties。

---

[12] 测试三，配置HelloService Bean。

src/main/java/net/mingyang/spring-boot-auto-config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_auto_config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import net.mingyang.spring_boot_test.HelloService;

@SpringBootApplication
public class Application {
   
   public static void main(String[] args) {
      SpringApplication.run(Application.class, args);
   }
   
   @Autowired
   HelloService helloService;
   
   @Bean
   public ApplicationRunner runner() {
      return new ApplicationRunner() {
         public void run(ApplicationArguments args) throws Exception {
            System.out.println("Text: " + helloService.getText());
         }
      };
   }

   @Bean
   public HelloService helloService() {
      HelloService helloService = new HelloService();
      helloService.setText("Application class");
      return helloService;
   }
}
{% endhighlight %}

Run:

{% highlight shell %}
D:\dev\spring-boot-auto-config> mvn spring-boot:run
Text: Application class
{% endhighlight %}

这里的HelloService Bean来源于Application。