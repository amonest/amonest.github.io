---
layout: post
title: Spring Boot - 导入外部Properties文件
---

Spring Boot 提供多种方式导入外部 **Properties** 文件。

---

src/main/resources/person.properties：

{% highlight properties %}
your.name=wang
your.age=25
your.sex=men
{% endhighlight %}

---

使用 **@PropertySource** 注解，可以指定外部 **Properties** 文件。

{% highlight java %}
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Repeatable(PropertySources.class)
public @interface PropertySource {

    /**
     * Indicate the resource location(s) of the properties file to be loaded.
     * For example, {@code "classpath:/com/myco/app.properties"} or
     * {@code "file:/path/to/file"}.
     * <p>Resource location wildcards (e.g. *&#42;/*.properties) are not permitted;
     * each location must evaluate to exactly one {@code .properties} resource.
     * <p>${...} placeholders will be resolved against any/all property sources already
     * registered with the {@code Environment}. See {@linkplain PropertySource above}
     * for examples.
     * <p>Each location will be added to the enclosing {@code Environment} as its own
     * property source, and in the order declared.
     */
    String[] value();
}
{% endhighlight %}

配合 **Environment** 类或 **@Value** 注解，可以读取 **Properties** 键值。

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.PropertySource;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
@PropertySource(value = { "classpath:person.properties" })
public class TestPropertySource implements CommandLineRunner {
    
    public void run(String... args) throws Exception {
        System.out.println("personFromValue: " + personFromValue());
        System.out.println("personFromEnvironment: " + personFromEnvironment());
    }
    
    @Autowired
    private Environment env;
    
    @Value("${your.name}")
    private String name;
    
    @Value("${your.sex}")
    private String sex;
    
    @Value("${your.age}")
    private Integer age;
    
    @Bean
    public PersonInfo personFromValue() {
        return new PersonInfo(name, age, sex);
    }
    
    @Bean
    public PersonInfo personFromEnvironment() {
        return new PersonInfo(env.getProperty("your.name"),
                Integer.parseInt(env.getProperty("your.age")),
                env.getProperty("your.sex"));
    }
    
    static class PersonInfo {
        private String name;
        private int age;
        private String sex;
        
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
        
        public String getSex() {
            return sex;
        }
        
        public void setSex(String sex) {
            this.sex = sex;
        }

        public PersonInfo(String name, int age, String sex) {
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

**@ConfigurationProperties** 注解提供另外一种批量读取 **Properties** 键值的方式。

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.PropertySource;
import org.springframework.stereotype.Component;

@Component
@PropertySource(value = { "classpath:person.properties" })
public class TestConfigurationProperties implements CommandLineRunner {
    
    public void run(String... args) throws Exception {
        System.out.println("TestConfigurationProperties: " + personInfo);
    }
    
    @Autowired
    private PersonInfo personInfo;
    
    @Component
    @ConfigurationProperties(prefix = "your")
    static class PersonInfo {
        ... ...
    }
}
{% endhighlight %}

如果上例中的 PersonInfo 类不能定义为 @Component，可以使用 **@ConfigurationProperties** 注解和 **@EnableConfigurationProperties** 注解配合方式。

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.PropertySource;
import org.springframework.stereotype.Component;

@Component
@PropertySource(value = { "classpath:person.properties" })
@EnableConfigurationProperties(TestEnableConfigurationProperties.PersonInfo.class)
public class TestEnableConfigurationProperties implements CommandLineRunner {
    
    public void run(String... args) throws Exception {
        System.out.println("TestEnableConfigurationProperties: " + personInfo);
    }
    
    @Autowired
    private PersonInfo personInfo;

    @ConfigurationProperties(prefix = "your")
    static class PersonInfo {
        ... ...
    }
}
{% endhighlight %}