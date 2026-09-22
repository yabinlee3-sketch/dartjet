import 'dart:convert';

import 'package:dart_jet/dart_jet.dart';

import '../kit/news_kit.dart';
import '../model/news_item.dart';
import 'sample_news.dart';

/// 新闻数据层，对应 Android net/NewsRepository.kt。
/// ViewModel 永远不知道数据来自网络还是离线兜底。
class NewsRepository extends XRepository {
  Future<List<NewsItem>> fetchTop(int limit) {
    return safe('news.top', () async {
      final ids = await _fetchIds();
      final items = <NewsItem>[];
      for (final id in ids.take(limit)) {
        final item = await _fetchItem(id);
        if (item != null) items.add(item);
      }
      return items;
    });
  }

  List<NewsItem> sample() => SampleNews.items;

  Future<List<int>> _fetchIds() async {
    final response = await XJet.getText(NewsKit.hnTopUrl);
    if (!response.isSuccess) {
      throw StateError('Hacker News responded ${response.status}');
    }
    final list = jsonDecode(response.bodyText) as List<dynamic>;
    return list.cast<int>();
  }

  Future<NewsItem?> _fetchItem(int id) async {
    final response = await XJet.getText('${NewsKit.hnItemUrl}/$id.json');
    if (!response.isSuccess) return null;
    final json = jsonDecode(response.bodyText) as Map<String, dynamic>;
    if (json['title'] == null) return null;
    return NewsItem.fromJson(json, id);
  }
}
