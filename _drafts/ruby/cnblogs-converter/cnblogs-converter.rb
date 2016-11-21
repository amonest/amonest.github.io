# -*- coding: utf-8 -*-
#
# cnblogs-cnblog
#
# CNBLOGS转换器。
# 将CNBLOGS产生的备份XML文件解析成Jekyll+Markdown样式。
#

require "rexml/document"

puts "dfsadf"

src = File.open("CNBlogs_BlogBackup_131_201001_201611.xml")
doc = REXML::Document.new(src)

for item in doc.root.elements
  puts 'xxxxxxxxx'

  puts item.elements['title']
end