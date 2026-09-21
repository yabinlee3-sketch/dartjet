import 'package:flutter/material.dart';
import '../core/providers.dart';
import '../core/route_registry.dart';

/// 基于 Navigator 1.0 的默认路由实现，对应 SimpleRouterProvider。
/// 页面通过 registerPage 注册，业务只接触 XJet.open(path, args)。
class MaterialRouterProvider implements RouterProvider {
  final RouteRegistry registry;
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, Widget Function(Map<String, Object?> args)> _builders = {};

  MaterialRouterProvider({
    required this.registry,
    required this.navigatorKey,
  });

  void registerPage(
    String route,
    Widget Function(Map<String, Object?> args) builder,
  ) {
    _builders[route] = builder;
  }

  bool hasPage(String route) => _builders.containsKey(route);

  @override
  void navigate(String route, Map<String, Object?> args) {
    final descriptor = registry.resolve(route);
    if (descriptor == null) {
      throw StateError('未知路由：$route');
    }
    final builder = _builders[route];
    if (builder == null) {
      throw StateError('路由 $route 未注册页面构造器');
    }
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw StateError('Navigator 尚未挂载');
    }
    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => builder(args),
        settings: RouteSettings(name: route),
      ),
    );
  }

  @override
  void back() {
    navigatorKey.currentState?.maybePop();
  }

  @override
  String? currentRoute() => null;
}
