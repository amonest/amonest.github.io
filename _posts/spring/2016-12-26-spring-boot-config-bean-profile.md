---
layout: post
title: "@Profile"
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

[3] src/main/java/net/mingyang/spring_boot_config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Profile;
import org.springframework.context.annotation.PropertySource;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Bean
    @Profile("prod")
    public StringService prodString() {
        return new StringService("prod");
    }
    
    @Bean
    @Profile("test")
    public StringService testString() {
        return new StringService("test");
    }
    
    static class StringService {
        private String text;

        public StringService(String text) {
            super();
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
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            @Autowired
            private ApplicationContext ctx;
            
            public void run(ApplicationArguments args) throws Exception {
                StringService service = ctx.getBean(StringService.class);
                System.out.println(service);
            }
        };
    }
}
{% endhighlight %}

---

[4] 运行时通过spring.profiles.active设置环境。

{% highlight shell %}
D:\dev\spring-boot-config> mvn spring-boot:run -Dspring.profiles.active=prod
StringService [text=prod]
{% endhighlight %}