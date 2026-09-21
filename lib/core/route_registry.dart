/// 路由描述，对应 Android RouteDescriptor。
class RouteDescriptor {
  final String path;
  final String group;
  final String title;

  const RouteDescriptor({
    required this.path,
    this.group = 'app',
    this.title = '',
  });
}

/// 运行期路由表，对应 Android RouteRegistry。
class RouteRegistry {
  final Map<String, RouteDescriptor> _routes = {};

  void register(RouteDescriptor descriptor, {bool override = false}) {
    final previous = _routes[descriptor.path];
    if (previous != null && !override) {
      throw StateError('路由 ${descriptor.path} 已注册（${previous.title}），请传入 override=true。');
    }
    _routes[descriptor.path] = descriptor;
  }

  RouteDescriptor? resolve(String route) => _routes[route];

  List<RouteDescriptor> all() {
    final list = _routes.values.toList()..sort((a, b) => a.path.compareTo(b.path));
    return list;
  }

  List<RouteDescriptor> byGroup(String group) =>
      all().where((d) => d.group == group).toList();

  bool has(String route) => _routes.containsKey(route);

  void clear() => _routes.clear();
}
