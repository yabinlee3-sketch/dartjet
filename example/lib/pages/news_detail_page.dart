import 'package:dart_jet/dart_jet.dart';
import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../repositories/favorites_dao.dart';

/// 新闻详情页，对应 Android NewsDetailActivity + NewsDetailScreen。
/// 演示默认内存数据库：收藏状态写入 DatabaseProvider 的 favorites 表。
class NewsDetailPage extends StatefulWidget {
  final NewsItem? item;
  final FavoritesDao? favoritesDao;

  const NewsDetailPage({super.key, this.item, this.favoritesDao});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late final FavoritesDao _dao;
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _dao = widget.favoritesDao ?? FavoritesDao(InMemoryDatabaseProvider());
    _favorite = _dao.contains(widget.item?.id ?? -1);
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.item;
    return Scaffold(
      appBar: AppBar(title: const Text('新闻详情')),
      body: news == null
          ? const Center(child: Text('没有这条新闻'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news.title,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(
                    '@${news.by} · ▲ ${news.score} · ${news.comments} 评论',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(news.url),
                  const SizedBox(height: 24),
                  FilledButton.tonalIcon(
                    icon: Icon(_favorite ? Icons.star : Icons.star_border),
                    label: Text(_favorite ? '取消收藏' : '收藏'),
                    onPressed: () {
                      setState(() {
                        _dao.toggle(news.id);
                        _favorite = _dao.contains(news.id);
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
