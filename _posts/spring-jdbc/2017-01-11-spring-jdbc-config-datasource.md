---
layout: post
title: Spring JDBC - 配置DataSource的三种方式
---

方式一、使用 **org.springframework.jdbc.datasource.DriverManagerDataSource**

说明：DriverManagerDataSource建立连接是只要有连接就新建一个connection，没有连接池的作用。 

{% highlight xml %}
<bean id="dataSource" class="org.springframework.jdbc.datasource.DriverManagerDataSource"> 
    <property name="driverClassName" value="${jdbc.driverClassName}" />
    <property name="url" value="${jdbc.url}" />
    <property name="username" value="${jdbc.username}" />
    <property name="password" value="${jdbc.password}" />
</bean> 
{% endhighlight %}

---

方式二、使用 **org.apache.commons.dbcp.BasicDataSource**

说明：这是一种推荐说明的数据源配置方式，它真正使用了连接池技术。

**DBCP(DataBase Connection Pool)** 是 Apache 上的一个 连接池项目，也是 Tomcat 使用的连接池组件。

配置DBCP：<http://commons.apache.org/proper/commons-dbcp/configuration.html>

{% highlight xml %}
<bean id="dataSource" class="org.apache.commons.dbcp.BasicDataSource"> 
    <property name="driverClassName" value="${jdbc.driver}" />
    <property name="url" value="${jdbc.url}" />
    <property name="username" value="${jdbc.username}" />
    <property name="password" value="${jdbc.password}" />
    <!--连接池启动时的初始化 -->
    <property name="initialSize" value="1" />
    <!--连接池的最大值 -->
    <property name="maxActive" value="30" />
    <!-- 最大空闲值，当经过一个高峰时间后，连接池可以慢慢将已经用不到的链接慢慢释放一部分，一直减少到 maxle为止 -->
    <property name="maxIdle" value="2" />
    <!-- 最小空闲值，当空闲的连接数少于阀值时，连接池就会预申请去一些链接，以免洪峰来时来不及申请 -->
    <property name="minIdle" value="1" />
    <!-- 运行判断连接超时任务的时间间隔，单位为毫秒，默认为-1，即不执行任务。 -->
    <property name="timeBetweenEvictionRunsMillis" value="3600000" />
    <!-- 连接的超时时间，默认为半小时。 -->
    <property name="minEvictableIdleTimeMillis" value="3600000" />
</bean> 
{% endhighlight %}

**C3P0** 是一个开源的JDBC连接池，它实现了数据源和JNDI绑定，支持JDBC3规范和JDBC2的标准扩展。

CP30文档：<http://www.mchange.com/projects/c3p0/>

快速入门：<http://www.mchange.com/projects/c3p0/#quickstart>

使用CP30: <http://www.mchange.com/projects/c3p0/#using_c3p0>

配置文件：<http://www.mchange.com/projects/c3p0/#configuration_files>

{% highlight xml %}
<bean id="dataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource"       
    destroy-method="close">
    <property name="driverClass" value="${jdbc.driver}" />
    <property name="jdbcUrl" value="${jdbc.url}" />
    <property name="user" value="${jdbc.username}" />
    <property name="password" value="${jdbc.password}" />
    <!-- 当连接池中的连接耗尽的时候c3p0一次同时获取的连接数。Default: 3 -->
    <property name="acquireIncrement" value="5" />
    <!-- 定义在从数据库获取新连接失败后重复尝试的次数。Default: 30 -->
    <property name="acquireRetryAttempts" value="30" />
    <!-- 两次连接中间隔时间，单位毫秒。Default: 1000 -->
    <property name="acquireRetryDelay" value="1000" />
    <!-- 连接关闭时默认将所有未提交的操作回滚。Default: false -->
    <property name="autoCommitOnClose" value="false" />
    <!--
      当连接池用完时客户端调用getConnection()后等待获取新连接的时间，超时后将抛出
      SQLException,如设为0则无限期等待。单位毫秒。Default: 0
    -->
    <property name="checkoutTimeout" value="10000" />
    <!-- 每60秒检查所有连接池中的空闲连接。Default: 0 -->
    <property name="idleConnectionTestPeriod" value="60" />
    <!-- 初始化时获取的连接数，取值应在minPoolSize与maxPoolSize之间。Default: 3 -->
    <property name="initialPoolSize" value="10" />
    <!-- 连接池中保留的最小连接数 -->
    <property name="minPoolSize" value="5" />
    <!-- 连接池中保留的最大连接数。Default: 15 -->
    <property name="maxPoolSize" value="30" />
    <!-- 最大空闲时间,60秒内未使用则连接被丢弃。若为0则永不丢弃。Default: 0 -->
    <property name="maxIdleTime" value="60" />
    <!--
      c3p0将建一张名为Test的空表，并使用其自带的查询语句进行测试。如果定义了这个参数那么
      属性preferredTestQuery将被忽略。你不能在这张Test表上进行任何操作，它将只供c3p0测试 使用。Default:
      null
    -->
    <property name="automaticTestTable" value="c3p0_TestTable" />
    <!--
      获取连接失败将会引起所有等待连接池来获取连接的线程抛出异常。但是数据源仍有效
      保留，并在下次调用getConnection()的时候继续尝试获取连接。如果设为true，那么在尝试
      获取连接失败后该数据源将申明已断开并永久关闭。Default: false
    -->
    <property name="breakAfterAcquireFailure" value="false" />
</bean>
{% endhighlight %}

---

方式三、使用 **org.springframework.jndi.JndiObjectFactoryBean**

说明：JndiObjectFactoryBean能够通过JNDI获取DataSource。

如果应用配置在高性能的应用服务器（如WebLogic或Websphere等）上，可能更希望使用应用服务器本身提供的数据源。应用服务器的数据源使用JNDI开放调用者使用，Spring为此专门提供引用JNDI资源的JndiObjectFactoryBean类。

{% highlight xml %}
<bean id="dataSource" class="org.springframework.jndi.JndiObjectFactoryBean"> 
    <property name="jndiName" value="Java:comp/env/jdbc/roseindiaDB_local" />
</bean> 
{% endhighlight %}

---

三种方式中的第一种没有使用连接池，故少在项目中用到，第三种方式需要在web server中配置数据源，不方便于部署，推荐使用第二种方式进行数据源的配置。 