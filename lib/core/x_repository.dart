import 'x_jet.dart';

/// Repository 基类，对应 Android XRepository。
/// 只操作数据源与 XJet Provider，不持有任何 UI。
abstract class XRepository {
  XJet get xjet => XJet.instance;

  /// 只上报，不重抛。
  void capture(String source, Object error) => XJet.capture(source, error);

  /// 先上报，再原样抛出。
  Future<T> safe<T>(String source, Future<T> Function() block) async {
    try {
      return await block();
    } catch (e) {
      capture(source, e);
      rethrow;
    }
  }
}
