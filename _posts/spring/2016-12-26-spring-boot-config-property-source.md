---
layout: post
title: "@PropertySource"
---

[1] 创建Maven项目。

---

[2] pom.xml：

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

[3] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.PropertySource;
import org.springframework.core.env.Environment;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            public void run(ApplicationArguments args) throws Exception {
                System.out.println("name = " + name);
                System.out.println("person = " + person());
            }
        };
    }
    
    @Value("${your.name}")
    private String name;
    
    @Autowired
    private Environment env;
    
    @Bean
    public PersonInfo person() {
        return new PersonInfo(env.getProperty("your.name"),
                env.getProperty("your.age"),
                env.getProperty("your.sex"));
    }
    
    static class PersonInfo {
        private String name;
        private String age;
        private String sex;

        public PersonInfo(String name, String age, String sex) {
            super();
            this.name = name;
            this.age = age;
            this.sex = sex;
        }

        @Override
        public String toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("PersonInfo [name=");
            builder.append(name);
            builder.append(", age=");
            builder.append(age);
            builder.append(", sex=");
            builder.append(sex);
            builder.append("]");
            return builder.toString();
        }
    }
}
{% endhighlight %}

---

[4] src/main/resources/config.properties:

{% highlight property %}
your.name=mingyang
your.age=25
your.sex=men
{% endhighlight %}

---

[5] 执行结果：

{% highlight shell %}
name = mingyang
person = PersonInfo [name=mingyang, age=25, sex=men]
{% endhighlight %}