---
layout : post
title : 安装Jekyll+Rouge
tag : [Jekyll, Rouge]
---

[Pygments](http://pygments.org/)是用Python写的，[Rouge](https://github.com/jneen/rouge)是用Ruby写的，所以[Jekyll](http://jekyllrb.com/)和Rouge配合使用更方便。

Rouge支持的语言：[List of supported languages and lexers](https://github.com/jneen/rouge/wiki/List-of-supported-languages-and-lexers)

---

[1] 进入<http://rubyinstaller.org/downloads/>, 根据自己的系统选择64-bit或32-bit的Ruby下载安装。

![ruby-setup-2](/assets/img/posts/ruby-setup-2.png)

---

[2] 根据自己的系统选择64-bit或32-bit的Development Kit下载。

---

[3] 安装Development Kit。

{% highlight shell %}
C:\Ruby23-x64\DevKit>ruby dk.rb init

C:\Ruby23-x64\DevKit>ruby dk.rb install
{% endhighlight %}

---

[4] 安装Jekyll。
{% highlight shell %}
C:\Ruby23-x64>gem install jekyll
{% endhighlight %}

---

[5] 安装Rouge。

{% highlight shell %}
C:\Ruby23-x64>gem install rouge
{% endhighlight %}

---

[6] Rouge需要CSS主题文件，通过rougify命令可以自动生成。

{% highlight shell %}
C:\amonest.github.io>rougify help style
usage: rougify style [<theme-name>] [<options>]

Print CSS styles for the given theme.  Extra options are
passed to the theme.  Theme defaults to thankful_eyes.

options:
  --scope       (default: .highlight) a css selector to scope by

available themes:
  base16, base16.dark, base16.monokai, base16.monokai.light, base16.solarized, base16.solarized.dark, 
  colorful, github, gruvbox, gruvbox.light, molokai, monokai, monokai.sublime, thankful_eyes

C:\amonest.github.io>rougify style thankful_eyes > assets/rouge.css
{% endhighlight %}

---

[7] 修改_config.yml文件。

{% highlight yaml %}
markdown: kramdown
highlighter: rouge
{% endhighlight %}

---

[8] 启动Jekyll本地服务器，通过http://localhost:4000/就可以看到生成网页了。

{% highlight shell %}
C:\amonest.github.io>jekyll server
Configuration file: C:/amonest.github.io/_config.yml
Configuration file: C:/amonest.github.io/_config.yml
            Source: C:/amonest.github.io
       Destination: C:/amonest.github.io/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
                    done in 0.316 seconds.
  Please add the following to your Gemfile to avoid polling for changes:
    gem 'wdm', '>= 0.1.0' if Gem.win_platform?
 Auto-regeneration: enabled for 'D:amonest.github.io'
Configuration file: C:/amonest.github.io/_config.yml
    Server address: http://127.0.0.1:4000/
  Server running... press ctrl-c to stop.
{% endhighlight %}
