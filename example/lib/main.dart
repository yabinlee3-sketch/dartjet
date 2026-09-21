import 'package:dart_jet/dart_jet.dart';
import 'package:flutter/material.dart';

import 'models/news_item.dart';
import 'pages/news_detail_page.dart';
import 'pages/news_list_page.dart';
import 'repositories/favorites_dao.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  // 数据层：默认内存数据库 + 收藏 DAO（演示 DatabaseProvider + DAO 注册）。
  final db = InMemoryDatabaseProvider();
  final favoritesDao = FavoritesDao(db);
  db.registerDao<FavoritesDao>(FavoritesDao, favoritesDao);

  final router = MaterialRouterProvider(
    registry: XJet.routes,
    navigatorKey: navigatorKey,
  )
    ..registerPage('news', (args) => const NewsListPage())
    ..registerPage('newsDetail', (args) => NewsDetailPage(
          item: args['item'] as NewsItem?,
          favoritesDao: favoritesDao,
        ));

  XJet.registerRoute('news', title: '头条');
  XJet.registerRoute('newsDetail', group: 'news', title: '新闻详情');

  XJet.init(
    XJetConfig(
      debug: true,
      installUncaughtErrorHandler: true,
      logTag: 'DartJetNews',
      router: router,
      database: db,
    ),
  );

  xJetRunApp(DartJetApp(navigatorKey: navigatorKey, router: router));
}

class DartJetApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final MaterialRouterProvider router;

  const DartJetApp({super.key, required this.navigatorKey, required this.router});

  @override
  Widget build(BuildContext context) {
    return XJetRouterScope(
      onNavigate: (route, args) => router.navigate(route, args),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'DartJet 头条',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const NewsListPage(),
      ),
    );
  }
}
