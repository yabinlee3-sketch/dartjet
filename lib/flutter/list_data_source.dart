import 'package:flutter/foundation.dart';

/// 列表数据源，对应 Android SimpleRecyclerAdapter 的数据态。
/// 支持 setData/addData/clear，并带上分页辅助字段。
class ListDataSource<T> extends ValueNotifier<List<T>> {
  ListDataSource([List<T> initial = const []])
      : super(List<T>.of(initial));

  bool hasMore = false;
  bool loadingMore = false;
  Object? loadMoreError;

  void setData(List<T> data) {
    value = List<T>.of(data);
  }

  void addData(List<T> data) {
    value = [...value, ...data];
  }

  void clear() {
    value = <T>[];
  }

  T item(int index) => value[index];

  List<T> data() => List<T>.of(value);
}
