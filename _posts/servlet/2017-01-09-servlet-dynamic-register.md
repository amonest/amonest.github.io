---
layout: post
title: Servlet API - 动态注册Servlet
---

Servlet 3.0 中可以动态注册 Servlet、Filter、Listener，在 **ServletContext** 对应注册API为：

{% highlight java %}
public interface ServletContext {
    public ServletRegistration.Dynamic addServlet(String servletName, String className); 
    public ServletRegistration.Dynamic addServlet(String servletName, Servlet servlet); 
    public ServletRegistration.Dynamic addServlet(String servletName, Class<? extends Servlet> servletClass); 

    public FilterRegistration.Dynamic addFilter(String filterName, String className); 
    public FilterRegistration.Dynamic addFilter(String filterName, Filter filter); 
    public FilterRegistration.Dynamic addFilter(String filterName, Class<? extends Filter> filterClass); 

    public void addListener(String className); 
    public <T extends EventListener> void addListener(T t); 
    public void addListener(Class<? extends EventListener> listenerClass);
}
{% endhighlight %}


动态注册 Servlet 有两种方法：

* 实现 **ServletContextListener** 接口，在 **contextInitialized** 方法中完成注册。

* 在jar文件中放入实现 **ServletContainerInitializer** 接口的初始化器。

先说在 **ServletContextListener** 监听器中完成注册。

{% highlight java %}
pubic class TestServletContextListener implements ServletContextListener {

    public void contextInitialized(ServletContextEvent sce) { 
        ServletContext sc = sce.getServletContext(); 

        // Register Servlet 
        ServletRegistration sr = sc.addServlet("DynamicServlet", 
            "web.servlet.dynamicregistration_war.TestServlet"); 
        sr.setInitParameter("servletInitName", "servletInitValue"); 
        sr.addMapping("/*"); 

        // Register Filter 
        FilterRegistration fr = sc.addFilter("DynamicFilter", 
            "web.servlet.dynamicregistration_war.TestFilter"); 
        fr.setInitParameter("filterInitName", "filterInitValue"); 
        fr.addMappingForServletNames(EnumSet.of(DispatcherType.REQUEST), 
                                     true, "DynamicServlet"); 

        // Register Listener 
        sc.addListener("web.servlet.dynamicregistration_war.TestServletRequestListener"); 
    }
}
{% endhighlight %}

再说说在jar文件中的 Servlet 组件注册，需要在jar包含 **META-INF/services/javax.servlet.ServletContainerInitializer** 文件，文件内容为已经实现 ServletContainerInitializer 接口的类。

{% highlight java %}
@HandlesTypes({ JarWelcomeServlet.class }) 
pubic class TestServletContainerInitializer implements ServletContainerInitializer {

  private static final Log log = LogFactory 
      .getLog(TestServletContainerInitializer.class); 

  private static final String JAR_HELLO_URL = "/jarhello"; 

  public void onStartup(Set<Class<?>> c, ServletContext servletContext) 
      throws ServletException { 
    log.info("TestServletContainerInitializer is loaded here..."); 
    
    log.info("now ready to add servlet : " + JarWelcomeServlet.class.getName()); 
    
    ServletRegistration.Dynamic servlet = servletContext.addServlet( 
        JarWelcomeServlet.class.getSimpleName(), 
        JarWelcomeServlet.class); 
    servlet.addMapping(JAR_HELLO_URL); 

    log.info("now ready to add filter : " + JarWelcomeFilter.class.getName()); 
    FilterRegistration.Dynamic filter = servletContext.addFilter( 
        JarWelcomeFilter.class.getSimpleName(), JarWelcomeFilter.class); 

    EnumSet<DispatcherType> dispatcherTypes = EnumSet 
        .allOf(DispatcherType.class); 
    dispatcherTypes.add(DispatcherType.REQUEST); 
    dispatcherTypes.add(DispatcherType.FORWARD); 

    filter.addMappingForUrlPatterns(dispatcherTypes, true, JAR_HELLO_URL); 

    log.info("now ready to add listener : " + JarWelcomeListener.class.getName()); 
    servletContext.addListener(JarWelcomeListener.class); 
  } 
}
{% endhighlight %}

其中 **@HandlesTypes** 注解表示 TestServletContainerInitializer 可以处理的类，在 **onStartup** 方法中，可以通过 Set<Class<?>> c 获取得到。