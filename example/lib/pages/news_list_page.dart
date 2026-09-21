import 'package:dart_jet/dart_jet.dart';
import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../viewmodels/news_view_model.dart';
import '../widgets/news_card.dart';

/// 新闻列表页，对应 Android NewsListActivity + NewsListScreen。
class NewsListPage extends XPage<NewsViewModel> {
  final NewsViewModel Function()? vmFactory;

  const NewsListPage({super.key, this.vmFactory});

  @override
  NewsViewModel createViewModel(BuildContext context) =>
      (vmFactory?.call()) ?? NewsViewModel();

  @override
  State<XPage<NewsViewModel>> createState() => _NewsListPageState();
}

class _NewsListPageState extends XPageState<NewsViewModel> {
  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('DartJet 头条')),
      body: XJetStateBox(
        state: vm.uiState.value,
        errorBuilder: (context, message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message ?? '网络不可用',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: vm.loadRemote,
                  child: const Text('重试联网'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: vm.loadSample,
                  child: const Text('离线示例数据'),
                ),
              ],
            ),
          ),
        ),
        empty: const Center(child: Text('暂时没有新闻')),
        content: Builder(
          builder: (context) => XListView<NewsItem>(
            source: vm.items,
            padding: const EdgeInsets.all(16),
            separator: const SizedBox(height: 12),
            itemBuilder: (context, item, index) => NewsCard(
              item: item,
              onTap: () => navigate('newsDetail', {'item': item}),
            ),
          ),
        ),
      ),
    );
  }
}
