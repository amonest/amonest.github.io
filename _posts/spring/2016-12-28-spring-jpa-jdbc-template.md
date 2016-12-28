---
layout: post
title: JdbcTemplate
---

[1] [《创建Maven项目》](/2016/12/28/spring-boot-create-maven-project)

---

[2] pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>

<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <scope>runtime</scope>
</dependency>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_test/Student.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

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

[4] src/main/java/net/mingyang/spring_boot_test/StudentService.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

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

[5] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }    
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            @Autowired
            StudentService studentService;
            
            public void run(ApplicationArguments args) throws Exception {
                List<Student> studentList = studentService.getList();
                for (Student student : studentList) {
                    System.out.println(student);
                }
            }
        };
    }
}
{% endhighlight %}

---

[6] src/main/resources/application.properties:

{% highlight ini %}
spring.datasource.url=jdbc:mysql://10.3.1.90:3306/test
spring.datasource.username=root
spring.datasource.password=
spring.datasource.driver-class-name=com.mysql.jdbc.Driver
{% endhighlight %}

---

[7] Run:

{% highlight shell %}
X:\dev\spring-boot-test> mvn spring-boot:run
Student [id=1, name=张三, score=95.0]
Student [id=2, name=李四, score=90.0]
Student [id=3, name=王五, score=100.0]
{% endhighlight %}