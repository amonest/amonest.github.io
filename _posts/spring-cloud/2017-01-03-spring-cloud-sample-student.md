---
layout: post
title: 实例(student)
---

[1] 创建项目cloth-student

---

[2] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.mingyang</groupId>
    <artifactId>cloud-student</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>cloud-student</name>
    <url>http://maven.apache.org</url>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <parent>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-parent</artifactId>
        <version>Brixton.SR7</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-eureka</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-config-client</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc</artifactId>
        </dependency>
        
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <scope>runtime</scope>
        </dependency>
    </dependencies>
</project>
{% endhighlight %}

这里 **spring-cloud-config-client** 提供 Config Client 支持。

---

[3] src/main/java/net/mingyang/cloud_student/Application.java：

{% highlight java %}
package net.mingyang.cloud_student;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.EnableEurekaClient;

@SpringBootApplication
@EnableEurekaClient
public class Application 
{
    public static void main( String[] args ) {
        SpringApplication.run(Application.class, args);
    }
}
{% endhighlight %}

---

[4] src/main/java/net/mingyang/cloud_student/Student.java：

{% highlight java %}
package net.mingyang.cloud_student;

import java.io.Serializable;

@SuppressWarnings("serial")
public class Student implements Serializable {

    private int id;
    private String name;
    private float score;
    
    public int getId() {
        return id;
    }
    
    public void setId(int id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }

    public float getScore() {
        return score;
    }

    public void setScore(float score) {
        this.score = score;
    }

    @Override
    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("Student [id=");
        builder.append(id);
        builder.append(", name=");
        builder.append(name);
        builder.append(", score=");
        builder.append(score);
        builder.append("]");
        return builder.toString();
    }
}
{% endhighlight %}

---

[5] src/main/java/net/mingyang/cloud_student/StudentService.java：

{% highlight java %}
package net.mingyang.cloud_student;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;

@Service
public class StudentService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<Student> getList() {
        String sql = "SELECT ID, NAME, SCORE FROM STUDENT";
        return (List<Student>) jdbcTemplate.query(sql, new RowMapper<Student>() {
            public Student mapRow(ResultSet rs, int rowNum) throws SQLException {
                Student student = new Student();
                student.setId(rs.getInt("ID"));
                student.setName(rs.getString("NAME"));
                student.setScore(rs.getFloat("SCORE"));
                return student;
            }
        });
    }
}
{% endhighlight %}

---

[6] src/main/java/net/mingyang/cloud_student/StudentController.java：

{% highlight java %}
package net.mingyang.cloud_student;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class StudentController {

    @Autowired
    private StudentService studentService;

    @RequestMapping(value = "/list")
    public List<Student> list() {
        List<Student> studentList = studentService.getList();
        return studentList;             
    }
}
{% endhighlight %}

---

[5] src/main/resources/bootstrap.properties：

{% highlight properties %}
eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/
spring.application.name=cloud-student

spring.cloud.config.uri=http://localhost:8762/
spring.cloud.config.profile=dev
{% endhighlight %}

应用配置从 Config Server 获取，这里实际配置地址为 **http://localhost:8762/cloud-student/dev**。
---

[4] src/main/resources/application.properties：

{% highlight properties %}
server.port=8771
{% endhighlight %}

---

[7] Run

{% highlight shell %}
X:\dev\cloud-student> mvn spring-boot:run
{% endhighlight %}