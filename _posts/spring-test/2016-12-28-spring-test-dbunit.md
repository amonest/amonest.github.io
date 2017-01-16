---
layout: post
title: Spring Test - dbunit测试
---

[1] pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.dbunit</groupId>
    <artifactId>dbunit</artifactId>
    <version>2.5.3</version>
    <scope>test</scope>
</dependency>
{% endhighlight %}

---

[2] src/test/java/net/mingyang/spring_boot_test/UserRepositoryTest.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;

import javax.sql.DataSource;

import org.dbunit.Assertion;
import org.dbunit.database.DatabaseConnection;
import org.dbunit.database.IDatabaseConnection;
import org.dbunit.dataset.IDataSet;
import org.dbunit.operation.DatabaseOperation;
import org.dbunit.util.fileloader.FlatXmlDataFileLoader;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.datasource.DataSourceUtils;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
public class UserRepositoryTest {

    @Autowired
    UserRepository userRepository;

    @Autowired
    private DataSource dataSource;

    private IDatabaseConnection connection;

    @Before
    public void init() throws Exception {
        connection = new DatabaseConnection(DataSourceUtils.getConnection(dataSource));
        DatabaseOperation.CLEAN_INSERT.execute(connection, loadXmlDataSet("/dbunit/users.xml"));
    }
    
    @Test
    public void testSave() throws Exception {
        User user = new User();
        user.setName("test");
        userRepository.save(user);
        
        assertThat(user.getId() > 0, is(true));
        
        Assertion.assertEqualsByQuery(
                loadXmlDataSet("/dbunit/users_updated.xml"), 
                connection, "select * from users", "users", new String[] { "id" });
    }
    
    private IDataSet loadXmlDataSet(String filename) throws Exception {
        return new FlatXmlDataFileLoader().load(filename);
    }
}
{% endhighlight %}

---

[3] src/test/resources/dbunit/users.xml:

{% highlight xml %}
<?xml version='1.0' encoding='UTF-8'?>
<dataset>
    <users id="1" name="admin" />
    <users id="2" name="demo" />
    <users id="3" name="guest" />
</dataset>
{% endhighlight %}

---

[4] src/test/resources/dbunit/users_updated.xml:

{% highlight xml %}
<?xml version='1.0' encoding='UTF-8'?>
<dataset>
    <users id="1" name="admin" />
    <users id="2" name="demo" />
    <users id="3" name="guest" />
    <users id="4" name="test" />
</dataset>
{% endhighlight %}