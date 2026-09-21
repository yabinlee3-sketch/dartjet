import 'service_provider.dart';

/// 运行期服务注册表，对应 Android `SpiRegistry`。
/// 键为 `Type`（Dart 无 `Class<T>` 映射）。
class SpiRegistry {
  final Map<Type, ServiceProvider<Object>> _providers = {};

  bool has(Type api) => _providers.containsKey(api);

  void register<T>(Type api, T implementation, {bool override = false}) {
    registerProvider<T>(api, InstanceProvider<T>(implementation),
        override: override);
  }

  void registerProvider<T>(Type api, ServiceProvider<T> provider,
      {bool override = false}) {
    final p = provider as ServiceProvider<Object>;
    if (_providers.containsKey(api) && !override) {
      throw StateError('SPI $api 已注册，请传入 override=true 替换默认实现。');
    }
    _providers[api] = p;
  }

  T? getOrNull<T>(Type api) {
    final provider = _providers[api];
    if (provider == null) return null;
    return (provider as ServiceProvider<T>).create();
  }

  T get<T>(Type api) {
    return getOrNull<T>(api) ??
        (throw StateError('没有为 $api 注册实现，请通过 XJet.register 或内置默认注册。'));
  }

  void unregister(Type api) => _providers.remove(api);

  Set<Type> get keys => _providers.keys.toSet();

  int get size => _providers.length;
}
