---
layout: post
title: 图书管理系统需求
---

### 一、主菜单



---

### 二、功能说明

---

#### 图书管理 - 登记

增加图书信息。

[1] 显示图书登记信息表单。表单栏位：

name

isdn

price

[2] 客户端提交时，验证表单数据。

name 不能为空。

isdn 不能为空。

[3] 控制器保存数据到books表。

---

#### 图书管理 - 登记

说明：增加图书信息。

实现：

[1] 显示图书登记信息表单。表单栏位：

name

isdn

price

[2] 客户端提交时，验证表单数据。

name 不能为空。

isdn 不能为空。

[3] 控制器保存数据到books表。




---

### 三、表结构

<table>
    <tr>
        <td colspan="3" style="padding: 0px;">
            <table class="outerless">
                <tr>
                    <th width="100">表名</th>
                    <td width="400">books</td>
                    <td>图书信息表</td>
                </tr>
            </table>
        </td>
    </tr>
    <tr>
        <th>字段</th>
        <th>类型</th>
        <th>说明</th>
    </tr>
    <tr>
        <td>bookId</td>
        <td>identity</td>
        <td>图书ID</td>
    </tr>
    <tr>
        <td>name</td>
        <td>varchar(200)</td>
        <td>图书名称</td>
    </tr>
</table>
