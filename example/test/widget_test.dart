import 'package:dart_jet/dart_jet.dart';
import 'package:dartjet_example/model/news_item.dart';
import 'package:dartjet_example/net/favorites_dao.dart';
import 'package:dartjet_example/net/news_repository.dart';
import 'package:dartjet_example/present/news_view_model.dart';
import 'package:dartjet_example/ui/news_detail_page.dart';
import 'package:dartjet_example/ui/news_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoNetworkRepository extends NewsRepository {
  @override
  Future<List<NewsItem>> fetchTop(int limit) async {
    throw StateError('offline');
  }
}

void main() {
  XJet.init(const XJetConfig(debug: false));

  testWidgets('新闻列表可加载离线示例数据', (tester) async {
    final vm = NewsViewModel(repository: _NoNetworkRepository());
    await tester.pumpWidget(
      MaterialApp(home: NewsListPage(vmFactory: () => vm)),
    );
    vm.loadSample();
    await tester.pumpAndSettle();
    expect(find.text('DartJet 头条'), findsOneWidget);
    expect(
      find.textContaining('DartJet：把 XJet 的开发思想带到 Flutter'),
      findsOneWidget,
    );
  });

  testWidgets('新闻列表错误态提供重试与离线入口', (tester) async {
    final vm = NewsViewModel(repository: _NoNetworkRepository());
    await tester.pumpWidget(
      MaterialApp(home: NewsListPage(vmFactory: () => vm)),
    );
    vm.loadRemote();
    await tester.pumpAndSettle();
    expect(find.text('重试联网'), findsOneWidget);
    expect(find.text('离线示例数据'), findsOneWidget);
  });

  testWidgets('新闻详情页展示数据', (tester) async {
    const item = NewsItem(
      id: 1,
      title: '标题',
      by: '作者',
      score: 5,
      comments: 2,
      url: 'https://example.com',
    );
    await tester.pumpWidget(
      const MaterialApp(home: NewsDetailPage(item: item)),
    );
    expect(find.text('标题'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);
  });

  testWidgets('新闻详情页可收藏并写入数据库表', (tester) async {
    final dao = FavoritesDao(InMemoryDatabaseProvider());
    const item = NewsItem(id: 1, title: '标题');
    await tester.pumpWidget(
      MaterialApp(
        home: NewsDetailPage(item: item, favoritesDao: dao),
      ),
    );
    expect(find.text('收藏'), findsOneWidget);
    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    expect(dao.contains(item.id), isTrue);
    expect(find.text('取消收藏'), findsOneWidget);
    await tester.tap(find.text('取消收藏'));
    await tester.pumpAndSettle();
    expect(dao.contains(item.id), isFalse);
  });
}
