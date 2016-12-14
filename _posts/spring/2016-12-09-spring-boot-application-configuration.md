---
layout: post
title: Spring Boot：配置说明
---

Spring Boot使用spring-boot-autoconfigure这个包完成自动配置，用户可以通过application.properties调整参数。以spring boot web为例：

---

[1] org.springframework.boot.autoconfigure.web.ResourceProperties读取application.properties：

{% highlight java %}
package org.springframework.boot.autoconfigure.web;

@ConfigurationProperties(prefix = "spring.resources", ignoreUnknownFields = false)
public class ResourceProperties implements ResourceLoaderAware {

  private static final String[] SERVLET_RESOURCE_LOCATIONS = { "/" };

  private static final String[] CLASSPATH_RESOURCE_LOCATIONS = {
      "classpath:/META-INF/resources/", "classpath:/resources/",
      "classpath:/static/", "classpath:/public/" };

  private static final String[] RESOURCE_LOCATIONS;

  static {
    RESOURCE_LOCATIONS = new String[CLASSPATH_RESOURCE_LOCATIONS.length
        + SERVLET_RESOURCE_LOCATIONS.length];
    System.arraycopy(SERVLET_RESOURCE_LOCATIONS, 0, RESOURCE_LOCATIONS, 0,
        SERVLET_RESOURCE_LOCATIONS.length);
    System.arraycopy(CLASSPATH_RESOURCE_LOCATIONS, 0, RESOURCE_LOCATIONS,
        SERVLET_RESOURCE_LOCATIONS.length, CLASSPATH_RESOURCE_LOCATIONS.length);
  }

  /**
   * Locations of static resources. Defaults to classpath:[/META-INF/resources/,
   * /resources/, /static/, /public/] plus context:/ (the root of the servlet context).
   */
  private String[] staticLocations = RESOURCE_LOCATIONS;

  public String[] getStaticLocations() {
    return this.staticLocations;
  }

  public void setStaticLocations(String[] staticLocations) {
    this.staticLocations = staticLocations;
  }

  public Resource getWelcomePage() {
    for (String location : getStaticWelcomePageLocations()) {
      Resource resource = this.resourceLoader.getResource(location);
      try {
        if (resource.exists()) {
          resource.getURL();
          return resource;
        }
      }
      catch (Exception ex) {
        // Ignore
      }
    }
    return null;
  }

  private String[] getStaticWelcomePageLocations() {
    String[] result = new String[this.staticLocations.length];
    for (int i = 0; i < result.length; i++) {
      String location = this.staticLocations[i];
      if (!location.endsWith("/")) {
        location = location + "/";
      }
      result[i] = location + "index.html";
    }
    return result;
  }

  List<Resource> getFaviconLocations() {
    List<Resource> locations = new ArrayList<Resource>(
        this.staticLocations.length + 1);
    if (this.resourceLoader != null) {
      for (String location : this.staticLocations) {
        locations.add(this.resourceLoader.getResource(location));
      }
    }
    locations.add(new ClassPathResource("/"));
    return Collections.unmodifiableList(locations);
  }

}
{% endhighlight %}

---

[2] org.springframework.boot.autoconfigure.web.WebMvcAutoConfiguration完成配置：

{% highlight java %}
package org.springframework.boot.autoconfigure.web;

@Configuration
@ConditionalOnWebApplication
@ConditionalOnClass({ Servlet.class, DispatcherServlet.class,
    WebMvcConfigurerAdapter.class })
@ConditionalOnMissingBean(WebMvcConfigurationSupport.class)
@AutoConfigureOrder(Ordered.HIGHEST_PRECEDENCE + 10)
@AutoConfigureAfter(DispatcherServletAutoConfiguration.class)
public class WebMvcAutoConfiguration {

  @Configuration
  @Import(EnableWebMvcConfiguration.class)
  @EnableConfigurationProperties({ WebMvcProperties.class, ResourceProperties.class })
  public static class WebMvcAutoConfigurationAdapter extends WebMvcConfigurerAdapter {

    private static final Log logger = LogFactory
        .getLog(WebMvcConfigurerAdapter.class);

    private final ResourceProperties resourceProperties;

    private final WebMvcProperties mvcProperties;

    private final ListableBeanFactory beanFactory;

    private final HttpMessageConverters messageConverters;

    final ResourceHandlerRegistrationCustomizer resourceHandlerRegistrationCustomizer;

    public WebMvcAutoConfigurationAdapter(ResourceProperties resourceProperties,
        WebMvcProperties mvcProperties, ListableBeanFactory beanFactory,
        HttpMessageConverters messageConverters,
        ObjectProvider<ResourceHandlerRegistrationCustomizer> resourceHandlerRegistrationCustomizerProvider) {
      this.resourceProperties = resourceProperties;
      this.mvcProperties = mvcProperties;
      this.beanFactory = beanFactory;
      this.messageConverters = messageConverters;
      this.resourceHandlerRegistrationCustomizer = resourceHandlerRegistrationCustomizerProvider
          .getIfAvailable();
    }

    @Override
    public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
      converters.addAll(this.messageConverters.getConverters());
    }

    @Override
    public void configureAsyncSupport(AsyncSupportConfigurer configurer) {
      Long timeout = this.mvcProperties.getAsync().getRequestTimeout();
      if (timeout != null) {
        configurer.setDefaultTimeout(timeout);
      }
    }

    @Override
    public void configureContentNegotiation(ContentNegotiationConfigurer configurer) {
      Map<String, MediaType> mediaTypes = this.mvcProperties.getMediaTypes();
      for (Entry<String, MediaType> mediaType : mediaTypes.entrySet()) {
        configurer.mediaType(mediaType.getKey(), mediaType.getValue());
      }
    }

    @Bean
    @ConditionalOnMissingBean
    public InternalResourceViewResolver defaultViewResolver() {
      InternalResourceViewResolver resolver = new InternalResourceViewResolver();
      resolver.setPrefix(this.mvcProperties.getView().getPrefix());
      resolver.setSuffix(this.mvcProperties.getView().getSuffix());
      return resolver;
    }

    @Bean
    @ConditionalOnBean(View.class)
    @ConditionalOnMissingBean
    public BeanNameViewResolver beanNameViewResolver() {
      BeanNameViewResolver resolver = new BeanNameViewResolver();
      resolver.setOrder(Ordered.LOWEST_PRECEDENCE - 10);
      return resolver;
    }

    @Bean
    @ConditionalOnBean(ViewResolver.class)
    @ConditionalOnMissingBean(name = "viewResolver", value = ContentNegotiatingViewResolver.class)
    public ContentNegotiatingViewResolver viewResolver(BeanFactory beanFactory) {
      ContentNegotiatingViewResolver resolver = new ContentNegotiatingViewResolver();
      resolver.setContentNegotiationManager(
          beanFactory.getBean(ContentNegotiationManager.class));
      // ContentNegotiatingViewResolver uses all the other view resolvers to locate
      // a view so it should have a high precedence
      resolver.setOrder(Ordered.HIGHEST_PRECEDENCE);
      return resolver;
    }

    @Bean
    @ConditionalOnMissingBean
    @ConditionalOnProperty(prefix = "spring.mvc", name = "locale")
    public LocaleResolver localeResolver() {
      if (this.mvcProperties
          .getLocaleResolver() == WebMvcProperties.LocaleResolver.FIXED) {
        return new FixedLocaleResolver(this.mvcProperties.getLocale());
      }
      AcceptHeaderLocaleResolver localeResolver = new AcceptHeaderLocaleResolver();
      localeResolver.setDefaultLocale(this.mvcProperties.getLocale());
      return localeResolver;
    }

    @Bean
    @ConditionalOnProperty(prefix = "spring.mvc", name = "date-format")
    public Formatter<Date> dateFormatter() {
      return new DateFormatter(this.mvcProperties.getDateFormat());
    }

    @Override
    public MessageCodesResolver getMessageCodesResolver() {
      if (this.mvcProperties.getMessageCodesResolverFormat() != null) {
        DefaultMessageCodesResolver resolver = new DefaultMessageCodesResolver();
        resolver.setMessageCodeFormatter(
            this.mvcProperties.getMessageCodesResolverFormat());
        return resolver;
      }
      return null;
    }

    @Override
    public void addFormatters(FormatterRegistry registry) {
      for (Converter<?, ?> converter : getBeansOfType(Converter.class)) {
        registry.addConverter(converter);
      }
      for (GenericConverter converter : getBeansOfType(GenericConverter.class)) {
        registry.addConverter(converter);
      }
      for (Formatter<?> formatter : getBeansOfType(Formatter.class)) {
        registry.addFormatter(formatter);
      }
    }

    private <T> Collection<T> getBeansOfType(Class<T> type) {
      return this.beanFactory.getBeansOfType(type).values();
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
      if (!this.resourceProperties.isAddMappings()) {
        logger.debug("Default resource handling disabled");
        return;
      }
      Integer cachePeriod = this.resourceProperties.getCachePeriod();
      if (!registry.hasMappingForPattern("/webjars/**")) {
        customizeResourceHandlerRegistration(
            registry.addResourceHandler("/webjars/**")
                .addResourceLocations(
                    "classpath:/META-INF/resources/webjars/")
            .setCachePeriod(cachePeriod));
      }
      String staticPathPattern = this.mvcProperties.getStaticPathPattern();
      if (!registry.hasMappingForPattern(staticPathPattern)) {
        customizeResourceHandlerRegistration(
            registry.addResourceHandler(staticPathPattern)
                .addResourceLocations(
                    this.resourceProperties.getStaticLocations())
            .setCachePeriod(cachePeriod));
      }
    }

    @Bean
    public WelcomePageHandlerMapping welcomePageHandlerMapping(
        ResourceProperties resourceProperties) {
      return new WelcomePageHandlerMapping(resourceProperties.getWelcomePage());
    }

    private void customizeResourceHandlerRegistration(
        ResourceHandlerRegistration registration) {
      if (this.resourceHandlerRegistrationCustomizer != null) {
        this.resourceHandlerRegistrationCustomizer.customize(registration);
      }

    }

    @Bean
    @ConditionalOnMissingBean({ RequestContextListener.class,
        RequestContextFilter.class })
    public static RequestContextFilter requestContextFilter() {
      return new OrderedRequestContextFilter();
    }

    @Configuration
    @ConditionalOnProperty(value = "spring.mvc.favicon.enabled", matchIfMissing = true)
    public static class FaviconConfiguration {

      private final ResourceProperties resourceProperties;

      public FaviconConfiguration(ResourceProperties resourceProperties) {
        this.resourceProperties = resourceProperties;
      }

      @Bean
      public SimpleUrlHandlerMapping faviconHandlerMapping() {
        SimpleUrlHandlerMapping mapping = new SimpleUrlHandlerMapping();
        mapping.setOrder(Ordered.HIGHEST_PRECEDENCE + 1);
        mapping.setUrlMap(Collections.singletonMap("**/favicon.ico",
            faviconRequestHandler()));
        return mapping;
      }

      @Bean
      public ResourceHttpRequestHandler faviconRequestHandler() {
        ResourceHttpRequestHandler requestHandler = new ResourceHttpRequestHandler();
        requestHandler
            .setLocations(this.resourceProperties.getFaviconLocations());
        return requestHandler;
      }

    }

  }

}
{% endhighlight %}