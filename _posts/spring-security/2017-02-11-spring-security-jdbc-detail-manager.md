---
layout: post
title: Spring Security - 数据库认证
---

数据库认证参考下面两个类：

org.springframework.security.core.userdetails.jdbc.JdbcDaoImpl：

{% highlight java %}
public class JdbcDaoImpl extends JdbcDaoSupport implements UserDetailsService {

    public static final String DEF_USERS_BY_USERNAME_QUERY = "select username,password,enabled "
            + "from users " + "where username = ?";
    public static final String DEF_AUTHORITIES_BY_USERNAME_QUERY = "select username,authority "
            + "from authorities " + "where username = ?";
    public static final String DEF_GROUP_AUTHORITIES_BY_USERNAME_QUERY = "select g.id, g.group_name, ga.authority "
            + "from groups g, group_members gm, group_authorities ga "
            + "where gm.username = ? " + "and g.id = ga.group_id "
            + "and g.id = gm.group_id";

    ... ...
}
{% endhighlight %}


---

org.springframework.security.provisioning.JdbcUserDetailsManager：

{% highlight java %}
public class JdbcUserDetailsManager extends JdbcDaoImpl implements UserDetailsManager,
        GroupManager {
    // ~ Static fields/initializers
    // =====================================================================================

    // UserDetailsManager SQL
    public static final String DEF_CREATE_USER_SQL = "insert into users (username, password, enabled) values (?,?,?)";
    public static final String DEF_DELETE_USER_SQL = "delete from users where username = ?";
    public static final String DEF_UPDATE_USER_SQL = "update users set password = ?, enabled = ? where username = ?";
    public static final String DEF_INSERT_AUTHORITY_SQL = "insert into authorities (username, authority) values (?,?)";
    public static final String DEF_DELETE_USER_AUTHORITIES_SQL = "delete from authorities where username = ?";
    public static final String DEF_USER_EXISTS_SQL = "select username from users where username = ?";
    public static final String DEF_CHANGE_PASSWORD_SQL = "update users set password = ? where username = ?";

    // GroupManager SQL
    public static final String DEF_FIND_GROUPS_SQL = "select group_name from groups";
    public static final String DEF_FIND_USERS_IN_GROUP_SQL = "select username from group_members gm, groups g "
            + "where gm.group_id = g.id" + " and g.group_name = ?";
    public static final String DEF_INSERT_GROUP_SQL = "insert into groups (group_name) values (?)";
    public static final String DEF_FIND_GROUP_ID_SQL = "select id from groups where group_name = ?";
    public static final String DEF_INSERT_GROUP_AUTHORITY_SQL = "insert into group_authorities (group_id, authority) values (?,?)";
    public static final String DEF_DELETE_GROUP_SQL = "delete from groups where id = ?";
    public static final String DEF_DELETE_GROUP_AUTHORITIES_SQL = "delete from group_authorities where group_id = ?";
    public static final String DEF_DELETE_GROUP_MEMBERS_SQL = "delete from group_members where group_id = ?";
    public static final String DEF_RENAME_GROUP_SQL = "update groups set group_name = ? where group_name = ?";
    public static final String DEF_INSERT_GROUP_MEMBER_SQL = "insert into group_members (group_id, username) values (?,?)";
    public static final String DEF_DELETE_GROUP_MEMBER_SQL = "delete from group_members where group_id = ? and username = ?";
    public static final String DEF_GROUP_AUTHORITIES_QUERY_SQL = "select g.id, g.group_name, ga.authority "
            + "from groups g, group_authorities ga "
            + "where g.group_name = ? "
            + "and g.id = ga.group_id ";
    public static final String DEF_DELETE_GROUP_AUTHORITY_SQL = "delete from group_authorities where group_id = ? and authority = ?";

    ... ...
}
{% endhighlight %}
