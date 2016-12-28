---
layout: post
title: JPA Repository
---

[1] [《创建Maven项目》](/2016/12/28/spring-boot-create-maven-project)

---

[2] pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <scope>runtime</scope>
</dependency>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_test/Teacher.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import java.io.Serializable;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;

@Entity(name = "teacher")
@SuppressWarnings("serial")
public class Teacher implements Serializable {

    @Id
    @GeneratedValue
    private int id;
    
    @Column(nullable = false)
    private String name;
    
    @Column(nullable = false)
    private int age;
    
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

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    @Override
    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("Teacher [id=");
        builder.append(id);
        builder.append(", name=");
        builder.append(name);
        builder.append(", age=");
        builder.append(age);
        builder.append("]");
        return builder.toString();
    }
}
{% endhighlight %}

---

[4] src/main/java/net/mingyang/spring_boot_test/TeacherRepository.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.data.repository.CrudRepository;

public interface TeacherRepository extends CrudRepository<Teacher, Integer> {

}
{% endhighlight %}

---

[5] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

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
            TeacherRepository teacherRepository;
            
            public void run(ApplicationArguments args) throws Exception {
                for (Teacher teacher : teacherRepository.findAll()) {
                    System.out.println(teacher);
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
Teacher [id=1, name=张老师, age=35]
Teacher [id=2, name=王老师, age=26]
Teacher [id=3, name=刘老师, age=47]
{% endhighlight %}