import 'package:flutter/material.dart';

import '../models/news_item.dart';

/// 单张新闻卡片。
class NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;

  const NewsCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('@${item.by}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Text('▲ ${item.score}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Text('${item.comments} 评论', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
