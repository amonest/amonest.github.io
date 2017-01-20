---
layout: post
title: Spring Test - 控制器测试
---

{% highlight java %}
package net.mingyang.spring_boot_test;

import static org.hamcrest.CoreMatchers.*;
import static org.junit.Assert.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.util.List;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.Rollback;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import net.mingyang.supercap_library.entity.Book;
import net.mingyang.supercap_library.service.BookService;

@RunWith(SpringRunner.class)
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@Rollback
public class BookControllerTest {
    
    @Autowired
    private MockMvc mvc;
    
    @Autowired
    private BookService bookService;

    Book book;
    
    @Before
    public void setUp() {
        book = new Book();
        book.setName("test");
        bookService.save(book);
    }
    
    @SuppressWarnings("unchecked")
    @Test
    public void testIndex() throws Exception {
        MvcResult result = mvc.perform(get("/books/index"))
            .andExpect(view().name("books/index"))
            .andExpect(model().attributeExists("bookList"))
            .andDo(print())
            .andReturn();
        
        List<Book> bookList = (List<Book>) 
                result.getModelAndView().getModel().get("bookList");
        assertThat(bookList, hasItems(book));
    }
}
{% endhighlight %}