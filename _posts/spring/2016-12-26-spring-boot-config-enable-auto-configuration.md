---
layout: post
title: "@EnableAutoConfiguration"
---

Spring Boot自动配置的关键是 **@EnableAutoConfiguration**。

---

参考[《@SpringBootApplication》](/2016/12/26/spring-boot-test-spring-boot-application)。

---

@EnableAutoConfiguration代码：

{% highlight java %}
package org.springframework.boot.autoconfigure;

@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import(EnableAutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration {
   Class<?>[] exclude() default {};
   String[] excludeName() default {};
}
{% endhighlight %}

---

这里的关键是@Import注解导入的配置功能 **EnableAutoConfigurationImportSelector**。

{% highlight java %}
public class EnableAutoConfigurationImportSelector
      implements DeferredImportSelector, BeanClassLoaderAware, ResourceLoaderAware,
      BeanFactoryAware, EnvironmentAware, Ordered {

   @Override
   public String[] selectImports(AnnotationMetadata metadata) {
      if (!isEnabled(metadata)) {
         return NO_IMPORTS;
      }
      try {
         AnnotationAttributes attributes = getAttributes(metadata);
         List<String> configurations = getCandidateConfigurations(metadata,
               attributes);
         configurations = removeDuplicates(configurations);
         Set<String> exclusions = getExclusions(metadata, attributes);
         configurations.removeAll(exclusions);
         configurations = sort(configurations);
         recordWithConditionEvaluationReport(configurations, exclusions);
         return configurations.toArray(new String[configurations.size()]);
      }
      catch (IOException ex) {
         throw new IllegalStateException(ex);
      }
   }

   protected List<String> getCandidateConfigurations(AnnotationMetadata metadata,
         AnnotationAttributes attributes) {
      List<String> configurations = SpringFactoriesLoader.loadFactoryNames(
            getSpringFactoriesLoaderFactoryClass(), getBeanClassLoader());
      Assert.notEmpty(configurations,
            "No auto configuration classes found in META-INF/spring.factories. If you "
                  + "are using a custom packaging, make sure that file is correct.");
      return configurations;
   }
}
{% endhighlight %}

---

**EnableAutoConfigurationImportSelector** 使用 **SpringFactoriesLoader.loadFactoryNames()** 方法扫描具有 **META-INF/spring.factories** 文件的jar包。

{% highlight java %}
public abstract class SpringFactoriesLoader {

   public static final String FACTORIES_RESOURCE_LOCATION = "META-INF/spring.factories";

   public static List<String> loadFactoryNames(Class<?> factoryClass, ClassLoader classLoader) {
      String factoryClassName = factoryClass.getName();
      try {
         Enumeration<URL> urls = (classLoader != null ? classLoader.getResources(FACTORIES_RESOURCE_LOCATION) :
               ClassLoader.getSystemResources(FACTORIES_RESOURCE_LOCATION));
         List<String> result = new ArrayList<String>();
         while (urls.hasMoreElements()) {
            URL url = urls.nextElement();
            Properties properties = PropertiesLoaderUtils.loadProperties(new UrlResource(url));
            String factoryClassNames = properties.getProperty(factoryClassName);
            result.addAll(Arrays.asList(StringUtils.commaDelimitedListToStringArray(factoryClassNames)));
         }
         return result;
      }
      catch (IOException ex) {
         throw new IllegalArgumentException("Unable to load [" + factoryClass.getName() +
               "] factories from location [" + FACTORIES_RESOURCE_LOCATION + "]", ex);
      }
   }
}
{% endhighlight %}

---

而 **spring-boot-autoconfigure-1.3.0.x.jar** 里就有一个 **spring.factories** 文件，此文件中声明了有哪些自动配置。

{% highlight ini %}
# Initializers
org.springframework.context.ApplicationContextInitializer=\
org.springframework.boot.autoconfigure.SharedMetadataReaderFactoryContextInitializer,\
org.springframework.boot.autoconfigure.logging.AutoConfigurationReportLoggingInitializer

# Application Listeners
org.springframework.context.ApplicationListener=\
org.springframework.boot.autoconfigure.BackgroundPreinitializer

# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.admin.SpringApplicationAdminJmxAutoConfiguration,\
org.springframework.boot.autoconfigure.aop.AopAutoConfiguration,\
org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration,\
org.springframework.boot.autoconfigure.MessageSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.PropertyPlaceholderAutoConfiguration,\
org.springframework.boot.autoconfigure.batch.BatchAutoConfiguration,\
org.springframework.boot.autoconfigure.cache.CacheAutoConfiguration,\
org.springframework.boot.autoconfigure.cassandra.CassandraAutoConfiguration,\
org.springframework.boot.autoconfigure.cloud.CloudAutoConfiguration,\
org.springframework.boot.autoconfigure.context.ConfigurationPropertiesAutoConfiguration,\
org.springframework.boot.autoconfigure.couchbase.CouchbaseAutoConfiguration,\
org.springframework.boot.autoconfigure.dao.PersistenceExceptionTranslationAutoConfiguration,\
org.springframework.boot.autoconfigure.data.cassandra.CassandraDataAutoConfiguration,\
org.springframework.boot.autoconfigure.data.cassandra.CassandraRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.couchbase.CouchbaseDataAutoConfiguration,\
org.springframework.boot.autoconfigure.data.couchbase.CouchbaseRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.elasticsearch.ElasticsearchAutoConfiguration,\
org.springframework.boot.autoconfigure.data.elasticsearch.ElasticsearchDataAutoConfiguration,\
org.springframework.boot.autoconfigure.data.elasticsearch.ElasticsearchRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.mongo.MongoDataAutoConfiguration,\
org.springframework.boot.autoconfigure.data.mongo.MongoRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.neo4j.Neo4jDataAutoConfiguration,\
org.springframework.boot.autoconfigure.data.neo4j.Neo4jRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.solr.SolrRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,\
org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.rest.RepositoryRestMvcAutoConfiguration,\
org.springframework.boot.autoconfigure.data.web.SpringDataWebAutoConfiguration,\
org.springframework.boot.autoconfigure.elasticsearch.jest.JestAutoConfiguration,\
org.springframework.boot.autoconfigure.freemarker.FreeMarkerAutoConfiguration,\
org.springframework.boot.autoconfigure.gson.GsonAutoConfiguration,\
org.springframework.boot.autoconfigure.h2.H2ConsoleAutoConfiguration,\
org.springframework.boot.autoconfigure.hateoas.HypermediaAutoConfiguration,\
org.springframework.boot.autoconfigure.hazelcast.HazelcastAutoConfiguration,\
org.springframework.boot.autoconfigure.hazelcast.HazelcastJpaDependencyAutoConfiguration,\
org.springframework.boot.autoconfigure.info.ProjectInfoAutoConfiguration,\
org.springframework.boot.autoconfigure.integration.IntegrationAutoConfiguration,\
org.springframework.boot.autoconfigure.jackson.JacksonAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.JdbcTemplateAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.JndiDataSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.XADataSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration,\
org.springframework.boot.autoconfigure.jms.JmsAutoConfiguration,\
org.springframework.boot.autoconfigure.jmx.JmxAutoConfiguration,\
org.springframework.boot.autoconfigure.jms.JndiConnectionFactoryAutoConfiguration,\
org.springframework.boot.autoconfigure.jms.activemq.ActiveMQAutoConfiguration,\
org.springframework.boot.autoconfigure.jms.artemis.ArtemisAutoConfiguration,\
org.springframework.boot.autoconfigure.jms.hornetq.HornetQAutoConfiguration,\
org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration,\
org.springframework.boot.autoconfigure.groovy.template.GroovyTemplateAutoConfiguration,\
org.springframework.boot.autoconfigure.jersey.JerseyAutoConfiguration,\
org.springframework.boot.autoconfigure.jooq.JooqAutoConfiguration,\
org.springframework.boot.autoconfigure.liquibase.LiquibaseAutoConfiguration,\
org.springframework.boot.autoconfigure.mail.MailSenderAutoConfiguration,\
org.springframework.boot.autoconfigure.mail.MailSenderValidatorAutoConfiguration,\
org.springframework.boot.autoconfigure.mobile.DeviceResolverAutoConfiguration,\
org.springframework.boot.autoconfigure.mobile.DeviceDelegatingViewResolverAutoConfiguration,\
org.springframework.boot.autoconfigure.mobile.SitePreferenceAutoConfiguration,\
org.springframework.boot.autoconfigure.mongo.embedded.EmbeddedMongoAutoConfiguration,\
org.springframework.boot.autoconfigure.mongo.MongoAutoConfiguration,\
org.springframework.boot.autoconfigure.mustache.MustacheAutoConfiguration,\
org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,\
org.springframework.boot.autoconfigure.reactor.ReactorAutoConfiguration,\
org.springframework.boot.autoconfigure.security.SecurityAutoConfiguration,\
org.springframework.boot.autoconfigure.security.SecurityFilterAutoConfiguration,\
org.springframework.boot.autoconfigure.security.FallbackWebSecurityAutoConfiguration,\
org.springframework.boot.autoconfigure.security.oauth2.OAuth2AutoConfiguration,\
org.springframework.boot.autoconfigure.sendgrid.SendGridAutoConfiguration,\
org.springframework.boot.autoconfigure.session.SessionAutoConfiguration,\
org.springframework.boot.autoconfigure.social.SocialWebAutoConfiguration,\
org.springframework.boot.autoconfigure.social.FacebookAutoConfiguration,\
org.springframework.boot.autoconfigure.social.LinkedInAutoConfiguration,\
org.springframework.boot.autoconfigure.social.TwitterAutoConfiguration,\
org.springframework.boot.autoconfigure.solr.SolrAutoConfiguration,\
org.springframework.boot.autoconfigure.velocity.VelocityAutoConfiguration,\
org.springframework.boot.autoconfigure.thymeleaf.ThymeleafAutoConfiguration,\
org.springframework.boot.autoconfigure.transaction.TransactionAutoConfiguration,\
org.springframework.boot.autoconfigure.transaction.jta.JtaAutoConfiguration,\
org.springframework.boot.autoconfigure.web.DispatcherServletAutoConfiguration,\
org.springframework.boot.autoconfigure.web.EmbeddedServletContainerAutoConfiguration,\
org.springframework.boot.autoconfigure.web.ErrorMvcAutoConfiguration,\
org.springframework.boot.autoconfigure.web.HttpEncodingAutoConfiguration,\
org.springframework.boot.autoconfigure.web.HttpMessageConvertersAutoConfiguration,\
org.springframework.boot.autoconfigure.web.MultipartAutoConfiguration,\
org.springframework.boot.autoconfigure.web.ServerPropertiesAutoConfiguration,\
org.springframework.boot.autoconfigure.web.WebClientAutoConfiguration,\
org.springframework.boot.autoconfigure.web.WebMvcAutoConfiguration,\
org.springframework.boot.autoconfigure.websocket.WebSocketAutoConfiguration,\
org.springframework.boot.autoconfigure.websocket.WebSocketMessagingAutoConfiguration,\
org.springframework.boot.autoconfigure.webservices.WebServicesAutoConfiguration

# Failure analyzers
org.springframework.boot.diagnostics.FailureAnalyzer=\
org.springframework.boot.autoconfigure.diagnostics.analyzer.NoSuchBeanDefinitionFailureAnalyzer,\
org.springframework.boot.autoconfigure.jdbc.DataSourceBeanCreationFailureAnalyzer,\
org.springframework.boot.autoconfigure.jdbc.HikariDriverConfigurationFailureAnalyzer

# Template availability providers
org.springframework.boot.autoconfigure.template.TemplateAvailabilityProvider=\
org.springframework.boot.autoconfigure.freemarker.FreeMarkerTemplateAvailabilityProvider,\
org.springframework.boot.autoconfigure.mustache.MustacheTemplateAvailabilityProvider,\
org.springframework.boot.autoconfigure.groovy.template.GroovyTemplateAvailabilityProvider,\
org.springframework.boot.autoconfigure.thymeleaf.ThymeleafTemplateAvailabilityProvider,\
org.springframework.boot.autoconfigure.velocity.VelocityTemplateAvailabilityProvider,\
org.springframework.boot.autoconfigure.web.JspTemplateAvailabilityProvider
{% endhighlight %}

---

使用 **-Ddebug** 可以查询Spring Boot自动配置过程。

{% highlight shell %}
D:\dev\spring-boot-test> mvn spring-boot:run -Ddebug
=========================
AUTO-CONFIGURATION REPORT
=========================


Positive matches:
-----------------

   GenericCacheConfiguration matched
      - Cache org.springframework.boot.autoconfigure.cache.GenericCacheConfiguration automatic cache type (CacheCondition)

   JmxAutoConfiguration matched
      - @ConditionalOnClass found required class 'org.springframework.jmx.export.MBeanExporter' (OnClassCondition)
      - @ConditionalOnProperty (spring.jmx.enabled=true) matched (OnPropertyCondition)

   JmxAutoConfiguration#mbeanExporter matched
      - @ConditionalOnMissingBean (types: org.springframework.jmx.export.MBeanExporter; SearchStrategy: current) did not find any beans (OnBeanCondition)

   JmxAutoConfiguration#mbeanServer matched
      - @ConditionalOnMissingBean (types: javax.management.MBeanServer; SearchStrategy: all) did not find any beans (OnBeanCondition)

   JmxAutoConfiguration#objectNamingStrategy matched
      - @ConditionalOnMissingBean (types: org.springframework.jmx.export.naming.ObjectNamingStrategy; SearchStrategy: current) did not find any beans (OnBeanCondition)

   NoOpCacheConfiguration matched
      - Cache org.springframework.boot.autoconfigure.cache.NoOpCacheConfiguration automatic cache type (CacheCondition)

   PropertyPlaceholderAutoConfiguration#propertySourcesPlaceholderConfigurer matched
      - @ConditionalOnMissingBean (types: org.springframework.context.support.PropertySourcesPlaceholderConfigurer; SearchStrategy: current) did not find any beans (OnBeanCondition)

   RedisCacheConfiguration matched
      - Cache org.springframework.boot.autoconfigure.cache.RedisCacheConfiguration automatic cache type (CacheCondition)

   SimpleCacheConfiguration matched
      - Cache org.springframework.boot.autoconfigure.cache.SimpleCacheConfiguration automatic cache type (CacheCondition)


Negative matches:
-----------------

   ActiveMQAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.jms.ConnectionFactory', 'org.apache.activemq.ActiveMQConnectionFactory' (OnClassCondition)

   AopAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.aspectj.lang.annotation.Aspect', 'org.aspectj.lang.reflect.Advice' (OnClassCondition)

   ArtemisAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.jms.ConnectionFactory', 'org.apache.activemq.artemis.jms.client.ActiveMQConnectionFactory' (OnClassCondition)

   BatchAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.batch.core.launch.JobLauncher', 'org.springframework.jdbc.core.JdbcOperations' (OnClassCondition)

   CacheAutoConfiguration did not match
      - @ConditionalOnClass found required class 'org.springframework.cache.CacheManager' (OnClassCondition)
      - @ConditionalOnBean (types: org.springframework.cache.interceptor.CacheAspectSupport; SearchStrategy: all) did not find any beans (OnBeanCondition)

   CacheAutoConfiguration.CacheManagerJpaDependencyConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean' (OnClassCondition)
      - Ancestor org.springframework.boot.autoconfigure.cache.CacheAutoConfiguration did not match (ConditionEvaluationReport.AncestorsMatchedCondition)

   CaffeineCacheConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.github.benmanes.caffeine.cache.Caffeine', 'org.springframework.cache.caffeine.CaffeineCacheManager' (OnClassCondition)

   CassandraAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'com.datastax.driver.core.Cluster' (OnClassCondition)

   CassandraDataAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.datastax.driver.core.Cluster', 'org.springframework.data.cassandra.core.CassandraAdminOperations' (OnClassCondition)

   CassandraRepositoriesAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.datastax.driver.core.Session', 'org.springframework.data.cassandra.repository.CassandraRepository' (OnClassCondition)

   CloudAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.cloud.config.java.CloudScanConfiguration' (OnClassCondition)

   CouchbaseAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.couchbase.client.java.CouchbaseBucket', 'com.couchbase.client.java.Cluster' (OnClassCondition)

   CouchbaseCacheConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.couchbase.client.java.Bucket', 'com.couchbase.client.spring.cache.CouchbaseCacheManager' (OnClassCondition)

   CouchbaseDataAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.couchbase.client.java.Bucket', 'org.springframework.data.couchbase.repository.CouchbaseRepository' (OnClassCondition)

   CouchbaseRepositoriesAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.couchbase.client.java.Bucket', 'org.springframework.data.couchbase.repository.CouchbaseRepository' (OnClassCondition)

   DataSourceAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseType' (OnClassCondition)

   DataSourceTransactionManagerAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.jdbc.core.JdbcTemplate', 'org.springframework.transaction.PlatformTransactionManager' (OnClassCondition)

   DeviceDelegatingViewResolverAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.mobile.device.view.LiteDeviceDelegatingViewResolver' (OnClassCondition)

   DeviceResolverAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.mobile.device.DeviceResolverHandlerInterceptor', 'org.springframework.mobile.device.DeviceHandlerMethodArgumentResolver' (OnClassCondition)

   DispatcherServletAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.web.servlet.DispatcherServlet' (OnClassCondition)

   EhCacheCacheConfiguration did not match
      - @ConditionalOnClass did not find required classes 'net.sf.ehcache.Cache', 'org.springframework.cache.ehcache.EhCacheCacheManager' (OnClassCondition)

   ElasticsearchAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.elasticsearch.client.Client', 'org.springframework.data.elasticsearch.client.TransportClientFactoryBean', 'org.springframework.data.elasticsearch.client.NodeClientFactoryBean' (OnClassCondition)

   ElasticsearchDataAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.elasticsearch.client.Client', 'org.springframework.data.elasticsearch.core.ElasticsearchTemplate' (OnClassCondition)

   ElasticsearchRepositoriesAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.elasticsearch.client.Client', 'org.springframework.data.elasticsearch.repository.ElasticsearchRepository' (OnClassCondition)

   EmbeddedMongoAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.mongodb.Mongo', 'de.flapdoodle.embed.mongo.MongodStarter' (OnClassCondition)

   EmbeddedServletContainerAutoConfiguration did not match
      - @ConditionalOnWebApplication (required) did not find web application classes (OnWebApplicationCondition)

   ErrorMvcAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.servlet.Servlet', 'org.springframework.web.servlet.DispatcherServlet' (OnClassCondition)

   FacebookAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.social.config.annotation.SocialConfigurerAdapter', 'org.springframework.social.facebook.connect.FacebookConnectionFactory' (OnClassCondition)

   FallbackWebSecurityAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.security.config.annotation.web.configuration.EnableWebSecurity' (OnClassCondition)

   FlywayAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.flywaydb.core.Flyway' (OnClassCondition)

   FreeMarkerAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'freemarker.template.Configuration', 'org.springframework.ui.freemarker.FreeMarkerConfigurationFactory' (OnClassCondition)

   GroovyTemplateAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'groovy.text.markup.MarkupTemplateEngine' (OnClassCondition)

   GsonAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'com.google.gson.Gson' (OnClassCondition)

   GuavaCacheConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.google.common.cache.CacheBuilder', 'org.springframework.cache.guava.GuavaCacheManager' (OnClassCondition)

   H2ConsoleAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.h2.server.web.WebServlet' (OnClassCondition)

   HazelcastAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'com.hazelcast.core.HazelcastInstance' (OnClassCondition)

   HazelcastCacheConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.hazelcast.core.HazelcastInstance', 'com.hazelcast.spring.cache.HazelcastCacheManager' (OnClassCondition)

   HazelcastJpaDependencyAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.hazelcast.core.HazelcastInstance', 'org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean' (OnClassCondition)

   HibernateJpaAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean', 'org.springframework.transaction.annotation.EnableTransactionManagement', 'javax.persistence.EntityManager' (OnClassCondition)

   HornetQAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.jms.ConnectionFactory', 'org.hornetq.api.jms.HornetQJMSClient' (OnClassCondition)

   HttpEncodingAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.web.filter.CharacterEncodingFilter' (OnClassCondition)

   HttpMessageConvertersAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.http.converter.HttpMessageConverter' (OnClassCondition)

   HypermediaAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.hateoas.Resource', 'org.springframework.web.bind.annotation.RequestMapping', 'org.springframework.plugin.core.Plugin' (OnClassCondition)

   InfinispanCacheConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.infinispan.spring.provider.SpringEmbeddedCacheManager' (OnClassCondition)

   IntegrationAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.integration.config.EnableIntegration' (OnClassCondition)

   JCacheCacheConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.cache.Caching', 'org.springframework.cache.jcache.JCacheCacheManager' (OnClassCondition)

   JacksonAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'com.fasterxml.jackson.databind.ObjectMapper' (OnClassCondition)

   JdbcTemplateAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.jdbc.core.JdbcTemplate' (OnClassCondition)

   JerseyAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.glassfish.jersey.server.spring.SpringComponentProvider', 'javax.servlet.ServletRegistration' (OnClassCondition)

   JestAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'io.searchbox.client.JestClient' (OnClassCondition)

   JmsAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.jms.core.JmsTemplate' (OnClassCondition)

   JndiConnectionFactoryAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.jms.core.JmsTemplate' (OnClassCondition)

   JndiDataSourceAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseType' (OnClassCondition)

   JooqAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.jooq.DSLContext' (OnClassCondition)

   JpaRepositoriesAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.data.jpa.repository.JpaRepository' (OnClassCondition)

   JtaAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'javax.transaction.Transaction' (OnClassCondition)

   LinkedInAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.social.config.annotation.SocialConfigurerAdapter', 'org.springframework.social.linkedin.connect.LinkedInConnectionFactory' (OnClassCondition)

   LiquibaseAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'liquibase.integration.spring.SpringLiquibase' (OnClassCondition)

   MailSenderAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'javax.mail.internet.MimeMessage' (OnClassCondition)

   MailSenderValidatorAutoConfiguration did not match
      - @ConditionalOnProperty (spring.mail.test-connection) did not find property 'test-connection' (OnPropertyCondition)

   MessageSourceAutoConfiguration did not match
      - ResourceBundle did not find bundle with basename messages (MessageSourceAutoConfiguration.ResourceBundleCondition)

   MongoAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'com.mongodb.MongoClient' (OnClassCondition)

   MongoDataAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.mongodb.Mongo', 'org.springframework.data.mongodb.core.MongoTemplate' (OnClassCondition)

   MongoRepositoriesAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'com.mongodb.Mongo', 'org.springframework.data.mongodb.repository.MongoRepository' (OnClassCondition)

   MultipartAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.servlet.Servlet', 'org.springframework.web.multipart.support.StandardServletMultipartResolver', 'javax.servlet.MultipartConfigElement' (OnClassCondition)

   MustacheAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'com.samskivert.mustache.Mustache' (OnClassCondition)

   Neo4jDataAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.neo4j.ogm.session.Neo4jSession', 'org.springframework.data.neo4j.template.Neo4jOperations' (OnClassCondition)

   Neo4jRepositoriesAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.neo4j.ogm.session.Neo4jSession', 'org.springframework.data.neo4j.repository.GraphRepository' (OnClassCondition)

   OAuth2AutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.security.oauth2.common.OAuth2AccessToken', 'org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter' (OnClassCondition)

   PersistenceExceptionTranslationAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.dao.annotation.PersistenceExceptionTranslationPostProcessor' (OnClassCondition)

   ProjectInfoAutoConfiguration#buildProperties did not match
      - @ConditionalOnResource did not find resource '${spring.info.build.location:classpath:META-INF/build-info.properties}' (OnResourceCondition)

   ProjectInfoAutoConfiguration#gitProperties did not match
      - GitResource did not find git info at classpath:git.properties (ProjectInfoAutoConfiguration.GitResourceAvailableCondition)

   RabbitAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.amqp.rabbit.core.RabbitTemplate', 'com.rabbitmq.client.Channel' (OnClassCondition)

   ReactorAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'reactor.spring.context.config.EnableReactor', 'reactor.Environment' (OnClassCondition)

   RedisAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.data.redis.connection.jedis.JedisConnection', 'org.springframework.data.redis.core.RedisOperations', 'redis.clients.jedis.Jedis' (OnClassCondition)

   RedisRepositoriesAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'redis.clients.jedis.Jedis', 'org.springframework.data.redis.repository.configuration.EnableRedisRepositories' (OnClassCondition)

   RepositoryRestMvcAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.data.rest.webmvc.config.RepositoryRestMvcConfiguration' (OnClassCondition)

   SecurityAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.security.authentication.AuthenticationManager', 'org.springframework.security.config.annotation.authentication.configurers.GlobalAuthenticationConfigurerAdapter' (OnClassCondition)

   SecurityFilterAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.security.web.context.AbstractSecurityWebApplicationInitializer', 'org.springframework.security.config.http.SessionCreationPolicy' (OnClassCondition)

   SendGridAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'com.sendgrid.SendGrid' (OnClassCondition)

   ServerPropertiesAutoConfiguration did not match
      - @ConditionalOnWebApplication (required) did not find web application classes (OnWebApplicationCondition)

   SessionAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.session.Session' (OnClassCondition)

   SitePreferenceAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.mobile.device.site.SitePreferenceHandlerInterceptor', 'org.springframework.mobile.device.site.SitePreferenceHandlerMethodArgumentResolver' (OnClassCondition)

   SocialWebAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.social.connect.web.ConnectController', 'org.springframework.social.config.annotation.SocialConfigurerAdapter' (OnClassCondition)

   SolrAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.apache.solr.client.solrj.impl.HttpSolrClient', 'org.apache.solr.client.solrj.impl.CloudSolrClient' (OnClassCondition)

   SolrRepositoriesAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.apache.solr.client.solrj.SolrClient', 'org.springframework.data.solr.repository.SolrRepository' (OnClassCondition)

   SpringApplicationAdminJmxAutoConfiguration did not match
      - @ConditionalOnProperty (spring.application.admin.enabled=true) did not find property 'enabled' (OnPropertyCondition)

   SpringDataWebAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.data.web.PageableHandlerMethodArgumentResolver', 'org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter' (OnClassCondition)

   ThymeleafAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.thymeleaf.spring4.SpringTemplateEngine' (OnClassCondition)

   TransactionAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.transaction.support.TransactionTemplate', 'org.springframework.transaction.PlatformTransactionManager' (OnClassCondition)

   TwitterAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.springframework.social.config.annotation.SocialConfigurerAdapter', 'org.springframework.social.twitter.connect.TwitterConnectionFactory' (OnClassCondition)

   VelocityAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'org.apache.velocity.app.VelocityEngine', 'org.springframework.ui.velocity.VelocityEngineFactory' (OnClassCondition)

   WebClientAutoConfiguration.RestTemplateConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.web.client.RestTemplate' (OnClassCondition)

   WebMvcAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.servlet.Servlet', 'org.springframework.web.servlet.DispatcherServlet', 'org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter' (OnClassCondition)

   WebServicesAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.ws.transport.http.MessageDispatcherServlet' (OnClassCondition)

   WebSocketAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.servlet.Servlet', 'javax.websocket.server.ServerContainer' (OnClassCondition)

   WebSocketMessagingAutoConfiguration did not match
      - @ConditionalOnClass did not find required class 'org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer' (OnClassCondition)

   XADataSourceAutoConfiguration did not match
      - @ConditionalOnClass did not find required classes 'javax.transaction.TransactionManager', 'org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseType' (OnClassCondition)


Exclusions:
-----------

    None


Unconditional classes:
----------------------

    org.springframework.boot.autoconfigure.info.ProjectInfoAutoConfiguration

    org.springframework.boot.autoconfigure.PropertyPlaceholderAutoConfiguration

    org.springframework.boot.autoconfigure.web.WebClientAutoConfiguration

    org.springframework.boot.autoconfigure.context.ConfigurationPropertiesAutoConfiguration
{% endhighlight %}