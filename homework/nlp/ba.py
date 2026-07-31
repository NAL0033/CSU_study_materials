import jieba
import numpy as np

from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_extraction.text import TfidfVectorizer


def load_stopwords(path):
    with open(path, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f]


def preprocess_text(text, stopwords):
    words = jieba.lcut(text.strip())
    return ' '.join([w for w in words if w not in stopwords and len(w) > 1])


def bow_vectorize(corpus):
    # 词袋模型：CountVectorizer
    vectorizer = CountVectorizer()
    X = vectorizer.fit_transform(corpus)

    print('词袋模型特征词：', vectorizer.get_feature_names_out())
    print('词频矩阵：')
    print(X.toarray())

    return X, vectorizer


def tfidf_transform(X_count):
    # TF-IDF 转换
    transformer = TfidfTransformer()
    X_tfidf = transformer.fit_transform(X_count)

    print('TF-IDF 权重矩阵：')
    print(np.round(X_tfidf.toarray(), 4))

    return X_tfidf


def tfidf_vectorize(corpus):
    # 一步完成 TF-IDF 向量化
    vectorizer = TfidfVectorizer()
    X = vectorizer.fit_transform(corpus)

    print('特征维度：', X.shape)
    print('特征词：', vectorizer.get_feature_names_out()[:20])

    return X, vectorizer


def news_vectorization(corpus_path, stopwords_path):
    stopwords = load_stopwords(stopwords_path)
    corpus = []

    with open(corpus_path, 'r', encoding='utf-8') as f:
        for line in f:
            corpus.append(preprocess_text(line, stopwords))

    # TF-IDF 向量化
    vectorizer = TfidfVectorizer(max_features=5000)
    X = vectorizer.fit_transform(corpus)

    print('文档数：', X.shape[0])
    print('特征数：', X.shape[1])
    print('前 10 个特征词：', vectorizer.get_feature_names_out()[:10])

    return X, vectorizer


if __name__ == '__main__':
    sample_corpus = [
        '这是一个测试文档',
        '这是第二个测试文档',
        '文档向量化是文本处理的重要步骤'
    ]

    # 示例 1：词袋模型
    X_count, vec = bow_vectorize(sample_corpus)

    # 示例 2：TF-IDF 转换
    tfidf_transform(X_count)

    # 示例 3：一步 TF-IDF
    tfidf_vectorize(sample_corpus)

    # 示例 4：新闻文本向量化，需准备数据文件
    # news_vectorization('data/news.txt', 'data/stop_words.txt')ppip