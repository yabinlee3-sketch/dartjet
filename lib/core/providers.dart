import 'dart:typed_data';

/// 缓存抽象，对应 Android CacheProvider。
abstract class CacheProvider {
  String? get(String key);
  void put(String key, String value);
  Uint8List? getBytes(String key);
  void putBytes(String key, Uint8List value);
  void remove(String key);
  void clear();
}

/// 事件总线抽象，对应 Android EventBusProvider。
abstract class EventBusProvider {
  Stream<T> events<T>();
  Stream<T> stickyEvents<T>();
  Future<void> post(Object event);
  Future<void> postSticky(Object event);
}

/// 数据库抽象，对应 Android DatabaseProvider。
/// Dart 无反射，DAO 由默认实现/业务通过 daoType 注册获取。
abstract class DatabaseProvider {
  T dao<T>(Type daoType);
  Future<T> transaction<T>(Future<T> Function() block);
  Future<void> clearAllTables();
  String databaseName();
}

/// 导航抽象，对应 Android RouterProvider。
abstract class RouterProvider {
  void navigate(String route, Map<String, Object?> args);
  void back();
  String? currentRoute();
}

/// 图片加载抽象，对应 Android ImageLoaderProvider。
abstract class ImageLoaderProvider {
  void load(String url, ImageLoadTarget target);
}

/// 图片加载回调目标。Flutter 没有 Bitmap，成功回调回传载体对象
/// （Phase 1 默认实现传 ImageProvider）。
abstract class ImageLoadTarget {
  void onLoadSuccess(Object image);
  void onLoadFailed(Object error);
}
