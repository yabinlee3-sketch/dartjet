import 'package:flutter/material.dart';
import 'list_data_source.dart';

/// 列表容器，对应 Android SimpleRecyclerAdapter + RecyclerView。
class XListView<T> extends StatelessWidget {
  final ListDataSource<T> source;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? separator;
  final EdgeInsets padding;
  final void Function()? onLoadMore;

  const XListView({
    super.key,
    required this.source,
    required this.itemBuilder,
    this.separator,
    this.padding = const EdgeInsets.all(0),
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<T>>(
      valueListenable: source,
      builder: (context, items, _) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (onLoadMore != null &&
                notification.metrics.extentAfter < 240 &&
                !source.loadingMore) {
              onLoadMore!();
            }
            return false;
          },
          child: ListView.builder(
            padding: padding,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final child = itemBuilder(context, item, index);
              if (separator != null && index < items.length - 1) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [child, separator!],
                );
              }
              return child;
            },
          ),
        );
      },
    );
  }
}
