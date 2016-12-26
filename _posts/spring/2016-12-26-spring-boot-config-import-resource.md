---
layout: post
title: "@ImportResource"
---

[1] 创建Maven项目。

---

[2] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.mingyang</groupId>
    <artifactId>spring-boot-config</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>spring-boot-config</name>
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

[3] src/main/java/net/mingyang/spring_boot_config/StringService.java：

{% highlight java %}
package net.mingyang.spring_boot_config;

public class StringService {
    private String text;
    
    public StringService() {
        super();
    }

    public StringService(String text) {
        super();
        this.text = text;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    @Override
    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("StringService [text=");
        builder.append(text);
        builder.append("]");
        return builder.toString();
    }
}
{% endhighlight %}

---

[4] src/main/resources/config.xml：

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:context="http://www.springframework.org/schema/context"
    xsi:schemaLocation="
        http://www.springframework.org/schema/beans 
        http://www.springframework.org/schema/beans/spring-beans.xsd 
        http://www.springframework.org/schema/context 
        http://www.springframework.org/schema/context/spring-context.xsd">
    
    <bean class="net.mingyang.spring_boot_config.StringService">
        <property name="text" value="HelloWorld" />
    </bean>
    
</beans>
{% endhighlight %}

---

[5] src/main/java/net/mingyang/spring_boot_config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ImportResource;

@SpringBootApplication
@ImportResource("classpath:config.xml")
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            @Autowired
            private ApplicationContext ctx;
            
            public void run(ApplicationArguments args) throws Exception {
                StringService stringService = ctx.getBean(StringService.class);
                System.out.println(stringService);
            }
        };
    }
}
{% endhighlight %}

---

[6] Run:

{% highlight shell %}
D:\dev\spring-boot-config> mvn spring-boot:run
StringService [text=HelloWorld]
{% endhighlight %}