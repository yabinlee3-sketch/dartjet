import 'providers.dart';

/// 默认内存数据库实现，对应 Android 的 Room 默认实现。
/// 无第三方依赖、跨平台；需要持久化时请替换为自定义 DatabaseProvider。
class InMemoryDatabaseProvider implements DatabaseProvider {
  final Map<Type, Object Function()> _daoFactories = {};
  final Map<String, List<Map<String, dynamic>>> _tables = {};

  InMemoryDatabaseProvider({Map<Type, Object Function()>? daos}) {
    if (daos != null) {
      _daoFactories.addAll(daos);
    }
  }

  /// 注册 DAO 实例；Dart 无反射，因此业务显式提供实例。
  void registerDao<T>(Type daoType, T dao) {
    _daoFactories[daoType] = () => dao as Object;
  }

  /// 注册 DAO 懒工厂。
  void registerDaoFactory<T>(Type daoType, T Function() factory) {
    _daoFactories[daoType] = () => factory() as Object;
  }

  @override
  T dao<T>(Type daoType) {
    final factory = _daoFactories[daoType];
    if (factory == null) {
      throw StateError('没有为 $daoType 注册 DAO 工厂，请先 registerDaoFactory。');
    }
    return factory() as T;
  }

  @override
  Future<T> transaction<T>(Future<T> Function() block) => block();

  @override
  Future<void> clearAllTables() async {
    _tables.clear();
  }

  @override
  String databaseName() => 'dartjet_inmemory';

  /// 供 DAO 使用的表访问器，拿不到的表会自动建表。
  List<Map<String, dynamic>> records(String table) =>
      _tables.putIfAbsent(table, () => <Map<String, dynamic>>[]);
}
