import jieba

s = "中南大学信息内容安全课程实验"

print("未加入自定义词典：", jieba.lcut(s))

jieba.add_word("信息内容安全")
jieba.add_word("中南大学")

print("加入自定义词典后：", jieba.lcut(s))
