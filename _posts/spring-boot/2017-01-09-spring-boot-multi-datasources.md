---
layout: post
title: Spring Boot - 配置多数据源
---

[1] **application.properties** 中添加数据源的信息。

{% highlight properties %}
spring.datasource.primary.url=jdbc:mysql://localhost:3306/test1
spring.datasource.primary.username=root
spring.datasource.primary.password=root
spring.datasource.primary.driverClassName=com.mysql.jdbc.Driver

spring.datasource.secondary.url=jdbc:mysql://localhost:3306/test2
spring.datasource.secondary.username=root
spring.datasource.secondary.password=root
spring.datasource.secondary.driverClassName=com.mysql.jdbc.Driver
{% endhighlight %}

---

[2] 配置多数据源。

{% highlight java %}
@Configuration
public class DataSourceConfiguration {

    @Bean(name = "primaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource.primary")
    @Primary
    public DataSource primaryDataSource(){
        return DataSourceBuilder.create().build();
    }

    @Bean(name = "secondaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource.secondary")
    public DataSource secondaryDataSource(){
        return DataSourceBuilder.create().build();
    }

    @Bean(name = "primaryJdbcTemplate")
    public JdbcTemplate primaryJdbcTemplate(
        @Qualifier("primaryDataSource") DataSource dataSource){
        return new JdbcTemplate(dataSource);
    }

    @Bean(name = "secondaryJdbcTemplate")
    public JdbcTemplate secondaryJdbcTemplate(
        @Qualifier("secondaryDataSource") DataSource dataSource){
        return new JdbcTemplate(dataSource);
    }
}
{% endhighlight %}

---

[3] **@Autowired** 注解与 **@Qualifier** 注解相配合，可以指定具体的 Bean。

{% highlight java %}
public class TestController {

    @Autowired
    @Qualifier("primaryDataSource")
    DataSource primaryDataSource;

    @Autowired
    @Qualifier("secondaryDataSource")
    DataSource secondaryDataSource;

    ... ...
}
{% endhighlight %}

因为主数据源使用了 **@Primary** 注解，所以可以省略对应的 **@Qualifier** 注解。

{% highlight java %}
public class TestController {

    @Autowired
    DataSource primaryDataSource;

    @Autowired
    @Qualifier("secondaryDataSource")
    DataSource secondaryDataSource;

    ... ...
}
{% endhighlight %}