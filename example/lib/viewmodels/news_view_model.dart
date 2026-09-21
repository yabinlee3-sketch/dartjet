import 'package:dart_jet/dart_jet.dart';

import '../models/news_item.dart';
import '../repositories/news_repository.dart';

/// 新闻页面 ViewModel，对应 Android NewsViewModel。
class NewsViewModel extends XViewModel {
  final NewsRepository repository;
  final ListDataSource<NewsItem> items = ListDataSource<NewsItem>();

  bool usingSample = false;

  NewsViewModel({NewsRepository? repository})
      : repository = repository ?? NewsRepository();

  @override
  void refresh() {
    if (usingSample) {
      loadSample();
    } else {
      loadRemote();
    }
  }

  void loadRemote() {
    setLoading();
    launchSafe('news.remote', () async {
      final list = await repository.fetchTop(20);
      items.setData(list);
      usingSample = false;
      setContent();
    });
  }

  void loadSample() {
    setLoading();
    launchSafe('news.sample', () async {
      items.setData(repository.sample());
      usingSample = true;
      setContent();
    });
  }

  @override
  void dispose() {
    items.dispose();
    super.dispose();
  }
}
