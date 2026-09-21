import 'dart:convert';
import 'registry.dart';
import 'service_provider.dart';

/// 配置文件式 SPI 发现（无反射版本）。
///
/// Dart 没有 `Class.forName`，因此用“API 名 / 工厂名”两张白名单，
/// 把 JSON 配置（`{"API_NAME":"FACTORY_NAME"}`）解析成注册调用。
class SpiConfig {
  final Map<String, Type> _apiNames = {};
  final Map<String, ServiceProvider<Object>> _factories = {};

  /// 注册 API 名 → 契约 Type。
  void registerApi(String name, Type api) => _apiNames[name] = api;

  /// 注册工厂名 → 懒工厂。
  void registerFactory(String name, ServiceProvider<Object> factory) =>
      _factories[name] = factory;

  bool hasApi(String name) => _apiNames.containsKey(name);
  bool hasFactory(String name) => _factories.containsKey(name);

  /// 解析 JSON：`{"API_NAME":"FACTORY_NAME"}`，返回成功注册的 API 列表。
  List<Type> loadJson(
    SpiRegistry registry,
    String json, {
    bool override = true,
  }) {
    final object = jsonDecode(json);
    if (object is! Map<String, dynamic>) {
      throw const FormatException('SPI 配置文件必须是 JSON 对象');
    }
    final registered = <Type>[];
    object.forEach((apiName, factoryName) {
      final api = _apiNames[apiName];
      final factory = _factories[factoryName as String];
      if (api == null) {
        throw StateError('未知 API 名：$apiName');
      }
      if (factory == null) {
        throw StateError('未知工厂名：$factoryName');
      }
      registry.registerProvider(api, factory, override: override);
      registered.add(api);
    });
    return registered;
  }
}
