---
layout : post
title : Sublime设置
---

{% highlight json %}
{
    "color_scheme": "Packages/Color Scheme - Default/Slush & Poppies.tmTheme",
    "font_size": 12.0,

    //把 tab 转换成4个空格
    "tab_size": 4,

    //把tab 转换成 空格
    "translate_tabs_to_spaces": true,

    //保存时自动把tab 转换成空格
    "expand_tabs_on_save": true,

/*
1.打开sublime的Preference -> Browser Packages ...
2.新建一个目录ExpandTabsOnSave
3.新建文件ExpandTabsOnSave.py
4.把下面内容复制进去，保存

import sublime, sublime_plugin, os

class ExpandTabsOnSave(sublime_plugin.EventListener):
    def on_pre_save(self, view):
        if view.settings().get('expand_tabs_on_save') == 1:
            view.window().run_command('expand_tabs')

*/

    //当某行为空格且无其它字符时, 保存时会去除空白
    "trim_trailing_white_space_on_save": true,

    //显示出空白字符
    "draw_white_space": "all",

    "update_check": false,
    "word_wrap": false
}
{% endhighlight %}