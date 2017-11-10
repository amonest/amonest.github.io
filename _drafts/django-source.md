---
layout: post
title: Django源码分析
---

### 读取settings.py文件
settings.py文件的内容可以通过django.conf.settings获取。

django.conf是模块，settings是模块中的一个变量。

{% highlight java %}
from django.conf import settings
installed_apps = settings.INSTALLED_APPS
{% endhighlight %}

---

### 读取安装的app

{% highlight java %}
from django.apps import apps

for app_config in apps.get_app_configs():
    print(app_config.name)
{% endhighlight %}

---


### 自动导入每个app下面的adminx模块

app应该是一个package，包含__init__.py文件。

adminx是一个module，也就是说它应该是app目录下的名为adminx.py的文件。

{% highlight java %}
from django.apps import apps
from importlib import import_module

for app_config in apps.get_app_configs():
    mod = import_module(app_config.name)
    # Attempt to import the app's admin module.
    try:
        before_import_registry = site.copy_registry()
        import_module('%s.adminx' % app_config.name)
    except:
        # Reset the model registry to the state before the last import as
        # this import will have to reoccur on the next request and this
        # could raise NotRegistered and AlreadyRegistered exceptions
        # (see #8245).
        site.restore_registry(before_import_registry)

        # Decide whether to bubble up this error. If the app just
        # doesn't have an admin module, we can ignore the error
        # attempting to import it, otherwise we want it to bubble up.
        if module_has_submodule(mod, 'adminx'):
            raise
{% endhighlight %}

---




### 动态的导入一个模块

{% highlight java %}
from importlib import import_module

try:
    xadmin_conf = getattr(settings, 'XADMIN_CONF', 'xadmin_conf.py')
    conf_mod = import_module(xadmin_conf)
except Exception:
    conf_mod = None
{% endhighlight %}

---



### xadmin.sites.AdminSite

AdminSite可以通过xadmin.sites.site获取。

xadmin.sites是模块，site是模块中的一个变量。

{% highlight java %}
# This global object represents the default admin site, for the common case.
# You can instantiate AdminSite in your own code to create a custom admin site.
site = AdminSite()
{% endhighlight %}


---

### View的继承关系

django.views.genericimport View


---

### xadmin的View继承关系

例如：LoginView

xadmin.views.website.LoginView -> 
    xadmin.views.base.BaseAdminView ->
        xadmin.views.base.BaseAdminObject ->
            object

例如：ListAdminView

xadmin.views.list.ListAdminView ->
    xadmin.views.base.ModelAdminView ->
        xadmin.views.base.CommAdminView ->
            xadmin.views.base.BaseAdminView ->
                xadmin.views.base.BaseAdminObject ->
                    object


---


### xadmin.