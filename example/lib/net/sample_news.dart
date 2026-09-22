import '../model/news_item.dart';

/// 离线兜底数据，对应 Android net/SampleNews.kt。
class SampleNews {
  static const List<NewsItem> items = [
    NewsItem(
      id: 1,
      title: 'DartJet：把 XJet 的开发思想带到 Flutter',
      by: 'dartjet',
      score: 128,
      comments: 24,
      url: 'https://example.com/dartjet',
    ),
    NewsItem(
      id: 2,
      title: '为什么 MVVM 四态适合快速开发资讯类 App',
      by: 'arch',
      score: 96,
      comments: 18,
      url: 'https://example.com/mvvm',
    ),
    NewsItem(
      id: 3,
      title: 'Provider/SPI：让业务层永远不碰到 Dio',
      by: 'contract',
      score: 77,
      comments: 9,
      url: 'https://example.com/provider',
    ),
  ];
}
