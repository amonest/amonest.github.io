---
layout: post
title: Spring Boot - 定义多环境@Profile
---

使用 **@Profile** 注解，可以定义多种运行环境。

{% highlight java %}
@Configuration
public class DataSourceConfiguration {
    
    @Bean
    @Profile("development")
    public DataSource devDataSource() {
        return new EmbeddedDatabaseBuilder()
            .setType(EmbeddedDatabaseType.HSQL)
            .addScript("classpath:com/bank/config/sql/schema.sql")
            .addScript("classpath:com/bank/config/sql/test-data.sql")
            .build();
    }

    @Bean
    @Profile("production")
    public DataSource proDataSource() throws Exception {
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName("com.mysql.jdbc.Driver");
        dataSource.setUrl("jdbc:mysql://localhost:3306/test");
        dataSource.setUsername("foo");
        dataSource.setPassword("foo");
        return dataSource;
    }
}
{% endhighlight %}

**@Profile** 可以用作元注解，可以用来编写自定义的注解。下面的例子定义了一个自定义的 **@Production** 注解，可以用来替代 **@Profile("production")**:

{% highlight java %}
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Profile("production")
public @interface Production {
}
{% endhighlight %}

Spring Boot 也支持外部配置文件 **application-{profile}.properties** 配置方式。

---

激活 Profile 可以采取多种方式，但是最直接的方式就是以编程的方式使用 **ApplicationContext** API：

{% highlight java %}
AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext();
ctx.getEnvironment().setActiveProfiles("development");
ctx.register(DataSourceConfiguration.class);
ctx.refresh();
{% endhighlight %}

此外，Profile 还可以以声明的方式通过 **spring.profiles.active** 属性来激活，可以通过系统环境变量、JVM系统属性、web.xml中的servlet上下文参数，甚至是JNDI中的一个条目来设置。

注意，Profile 不是“二选一”的，你可以一次激活多个 Profile。以编程方式，只需要在 **setActiveProfiles()** 方法提供多个 Profile 的名字即可：

{% highlight java %}
ctx.getEnvironment().setActiveProfiles("profile1", "profile2");
{% endhighlight %}

声明形式中，**spring.profiles.active** 可以接收逗号隔开的配置名字列表：

{% highlight java %}
-Dspring.profiles.active="profile1,profile2"
{% endhighlight %}