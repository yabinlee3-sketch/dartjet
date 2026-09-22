import 'package:dart_jet/dart_jet.dart';
import 'package:flutter/material.dart';

import '../kit/news_kit.dart';
import '../model/news_item.dart';
import '../net/favorites_dao.dart';
import '../ui/news_detail_page.dart';
import '../ui/news_list_page.dart';

/// 应用装配 + 根组件，对应 Android xjet-news-demo 的 app/NewsDemoApp.kt。
NewsApp createNewsApp() {
  final navigatorKey = GlobalKey<NavigatorState>();

  // 数据层：默认内存数据库 + 收藏 DAO（演示 DatabaseProvider + DAO 注册）。
  final db = InMemoryDatabaseProvider();
  final favoritesDao = FavoritesDao(db);
  db.registerDao<FavoritesDao>(FavoritesDao, favoritesDao);

  final router =
      MaterialRouterProvider(registry: XJet.routes, navigatorKey: navigatorKey)
        ..registerPage(NewsKit.routeNews, (args) => const NewsListPage())
        ..registerPage(
          NewsKit.routeNewsDetail,
          (args) => NewsDetailPage(
            item: args['item'] as NewsItem?,
            favoritesDao: favoritesDao,
          ),
        );

  XJet.registerRoute(NewsKit.routeNews, title: NewsKit.titleNews);
  XJet.registerRoute(
    NewsKit.routeNewsDetail,
    group: 'news',
    title: NewsKit.titleNewsDetail,
  );

  XJet.init(
    XJetConfig(
      debug: true,
      installUncaughtErrorHandler: true,
      logTag: 'DartJetNews',
      router: router,
      database: db,
    ),
  );

  return NewsApp(navigatorKey: navigatorKey, router: router);
}

class NewsApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final MaterialRouterProvider router;

  const NewsApp({super.key, required this.navigatorKey, required this.router});

  @override
  Widget build(BuildContext context) {
    return XJetRouterScope(
      onNavigate: (route, args) => router.navigate(route, args),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: NewsKit.titleNews,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const NewsListPage(),
      ),
    );
  }
}
