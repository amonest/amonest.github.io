---
layout: post
title: JdbcTemplate
---

{% highlight java %}
@Service
public class StudentService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<Student> getList() {
        String sql = "SELECT ID, NAME, SCORE FROM STUDENT";
        return (List<Student>) jdbcTemplate.query(sql, new RowMapper<Student>() {
            public Student mapRow(ResultSet rs, int rowNum) throws SQLException {
                Student student = new Student();
                student.setId(rs.getInt("ID"));
                student.setName(rs.getString("NAME"));
                student.setScore(rs.getFloat("SCORE"));
                return student;
            }
        });
    }
}
{% endhighlight %}