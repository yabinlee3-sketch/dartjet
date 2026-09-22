import 'package:dart_jet/dart_jet.dart';

/// 收藏 DAO：把收藏 id 存在默认数据库的 `favorites` 表里。
class FavoritesDao {
  final InMemoryDatabaseProvider db;

  FavoritesDao(this.db);

  bool contains(int id) =>
      db.records('favorites').any((row) => row['id'] == id);

  void add(int id) {
    db.records('favorites').removeWhere((row) => row['id'] == id);
    db.records('favorites').add({'id': id});
  }

  void remove(int id) {
    db.records('favorites').removeWhere((row) => row['id'] == id);
  }

  void toggle(int id) {
    if (contains(id)) {
      remove(id);
    } else {
      add(id);
    }
  }
}
