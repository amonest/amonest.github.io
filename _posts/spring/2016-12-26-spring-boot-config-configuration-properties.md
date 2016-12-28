---
layout: post
title: "@ConfigurationProperties"
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
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Component;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Component
    @ConfigurationProperties(prefix = "your")
    static class PersonInfo {
        private String name;
        private String age;
        private String sex;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getAge() {
            return age;
        }

        public void setAge(String age) {
            this.age = age;
        }

        public String getSex() {
            return sex;
        }

        public void setSex(String sex) {
            this.sex = sex;
        }

        public PersonInfo() {
            super();
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
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            @Autowired
            private ApplicationContext ctx;
            
            public void run(ApplicationArguments args) throws Exception {
                PersonInfo personInfo = ctx.getBean(PersonInfo.class);
                System.out.println(personInfo);
            }
        };
    }
}
{% endhighlight %}

---

[4] src/main/resources/application.properties:

{% highlight property %}
your.name=mingyang
your.age=25
your.sex=men
{% endhighlight %}

---

[5] 执行结果：

{% highlight shell %}
D:\dev\spring-boot-test> mvn spring-boot:run
PersonInfo [name=mingyang, age=25, sex=men]
{% endhighlight %}