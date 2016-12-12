---
layout: post
title: Spring Boot Web集成JDBC
---

[1] 执行[《创建Web项目》](/2016/12/09/spring-boot-web-create-project)。

---

[2] 执行[《集成Thymeleaf》](/2016/12/09/spring-boot-web-integrate-thymeleaf)。


---

[3] 修改pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>

<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
</dependency>
{% endhighlight %}

---

[4] 修改application.properties。

{% highlight ini %}
spring.datasource.url=jdbc:mysql://10.3.1.90:3306/test
spring.datasource.username=root
spring.datasource.password=
spring.datasource.driver-class-name=com.mysql.jdbc.Driver
{% endhighlight %}

---

[5] 创建Student.java。

{% highlight java %}
package net.mingyang.spring_boot_helloworld;

import java.io.Serializable;

@SuppressWarnings("serial")
public class Student implements Serializable {

    private int id;
    private String name;
    private float sumScore;
    private float avgScore;
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
    
    public float getSumScore() {
        return sumScore;
    }
    
    public void setSumScore(float sumScore) {
        this.sumScore = sumScore;
    }
    
    public float getAvgScore() {
        return avgScore;
    }
    
    public void setAvgScore(float avgScore) {
        this.avgScore = avgScore;
    }
    
    public int getAge() {
        return age;
    }
    
    public void setAge(int age) {
        this.age = age;
    }
}
{% endhighlight %}

---

[6] 创建StudentService.java。

{% highlight java %}
package net.mingyang.spring_boot_helloworld;

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
        String sql = "SELECT ID, NAME, AGE, SCORE_SUM, SCORE_AVG FROM STUDENT";
        return (List<Student>) jdbcTemplate.query(sql, new RowMapper<Student>() {

            public Student mapRow(ResultSet rs, int rowNum) throws SQLException {
                Student stu = new Student();
                stu.setId(rs.getInt("ID"));
                stu.setName(rs.getString("NAME"));
                stu.setAge(rs.getInt("AGE"));
                stu.setSumScore(rs.getFloat("SCORE_SUM"));
                stu.setAvgScore(rs.getFloat("SCORE_AVG"));
                return stu;
            }
            
        });
    }
}
{% endhighlight %}

---

[7] 创建StudentController.java。

{% highlight java %}
package net.mingyang.spring_boot_helloworld;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class StudentController {
    
    @Autowired
    private StudentService studentService;
    
    @RequestMapping(value ="/student", method = RequestMethod.GET)
    public String list(Model model) {
        List<Student> list = studentService.getList();
        model.addAttribute("list", list);
        return "student_list";
    }
}
{% endhighlight %}

---

[8] 创建模板src/resources/templates/student_list.html。

{% highlight html %}
<!DOCTYPE HTML>
<html xmlns:th="http://www.thymeleaf.org">
<head>
<title>Student List</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
    <table border="1">
        <tr>
            <th>ID</th>
            <th>学员</th>
            <th>年龄</th>
            <th>总成绩</th>
            <th>平均成绩</th>
        </tr>
        <tr th:each="student : ${list}">
            <td th:text="${student.id}" />
            <td th:text="${student.name}" />
            <td th:text="${student.age}" />
            <td th:text="${student.sumScore}" />
            <td th:text="${student.avgScore}" />
        </tr>
    </table>
</body>
</html>
{% endhighlight %}

---

[9] 启动应用程序，访问http://localhost:8080/student，测试是否成功。

![spring-boot-web-integrate-jdbc](/assets/img/posts/spring-boot-web-integrate-jdbc.png)