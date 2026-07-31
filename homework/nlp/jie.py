import jieba
import jieba.posseg as pseg


def precise_seg(s):
    return jieba.lcut(s, cut_all=False)


def full_seg(s):
    return jieba.lcut(s, cut_all=True)


def search_seg(s):
    return jieba.lcut_for_search(s)


def pos_seg(s):
    return pseg.lcut(s)


def normalize_name(w):
    if w in ['孟德', '丞相']:
        return '曹操'
    elif w in ['玄德', '玄德曰']:
        return '刘备'
    elif w in ['孔明', '孔明曰']:
        return '诸葛亮'
    elif w in ['关公', '云长']:
        return '关羽'
    return w


def top20_words():
    txt = open(r'D:\作业\nlp\data\threekingdoms.txt', 'r', encoding='utf-8').read()
    words = jieba.lcut(txt)

    counts = {}

    stopwords = {
        '将军', '却说', '荆州', '二人', '不可', '不能', '如此', '今日',
        '次日', '于是', '如何', '主公', '一人', '不敢', '大喜', '陛下',
        '不知', '汉中', '只见', '都督', '后主'
    }

    for w in words:
        if len(w) == 1:
            continue

        if w in stopwords:
            continue

        w = normalize_name(w)
        counts[w] = counts.get(w, 0) + 1

    li = list(counts.items())
    li.sort(key=lambda x: x[1], reverse=True)

    print('三国演义前20高频词：')
    for i in range(20):
        print('{:<3}{:<8}{:>6}'.format(i + 1, li[i][0], li[i][1]))


def people_count():
    txt = open(r'D:\作业\nlp\data\threekingdoms.txt', 'r', encoding='utf-8').read()
    words = jieba.lcut(txt)

    counts = {}

    people = [
        '曹操', '诸葛亮', '刘备', '关羽', '张飞', '吕布', '赵云', '姜维',
        '周瑜', '孙权', '司马懿', '黄忠', '马超', '魏延', '庞统', '袁绍'
    ]

    for w in words:
        if len(w) == 1:
            continue

        w = normalize_name(w)
        counts[w] = counts.get(w, 0) + 1

    result = {k: v for k, v in counts.items() if k in people}
    li = list(result.items())
    li.sort(key=lambda x: x[1], reverse=True)

    print('主要人物出场次数：')
    for name, count in li:
        print('{:<8}{:>6}'.format(name, count))


if __name__ == '__main__':
    s = '中南大学信息内容安全课程实验'

    print('精确模式：', precise_seg(s))
    print('全模式：', full_seg(s))
    print('搜索模式：', search_seg(s))
    print('词性标注：', pos_seg(s))

    top20_words()
    people_count()