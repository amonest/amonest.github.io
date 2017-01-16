---
layout: post
title: Spring JDBC - 嵌入式HSQLDB
---

pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.hsqldb</groupId>
    <artifactId>hsqldb</artifactId>
    <scope>runtime</scope>
</dependency>
{% endhighlight %}

application.properties：

{% highlight properties %}
spring.datasource.driverClassName=org.hsqldb.jdbcDriver
spring.datasource.url=jdbc:hsqldb:mem:test
spring.datasource.username=sa
spring.datasource.password=
{% endhighlight %}

使用Java Config：

{% highlight java %}
@Configuration
public class DataSourceConfiguration {
    
    @Bean
    public DataSource dataSource() {
        return new EmbeddedDatabaseBuilder()
            .setType(EmbeddedDatabaseType.HSQL)
            .addScript("classpath:com/bank/config/sql/schema.sql")
            .addScript("classpath:com/bank/config/sql/test-data.sql")
            .build();
    }
}
{% endhighlight %}