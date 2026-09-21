import 'dart:convert';
import 'dart:typed_data';

import 'database_defaults.dart';
import 'defaults.dart';
import 'exception_interceptor.dart';
import 'log.dart';
import 'net.dart';
import 'permission_service.dart';
import 'providers.dart';
import 'registry.dart';
import 'route_registry.dart';
import 'service_provider.dart';
import 'spi_config.dart';

/// DartJet 初始化配置。
class XJetConfig {
  final bool debug;
  final bool autoDiscoverConfig;
  final DatabaseProvider? database;
  final CacheProvider? cache;
  final EventBusProvider? eventBus;
  final RouterProvider? router;
  final ImageLoaderProvider? imageLoader;
  final HttpProvider? http;
  final PermissionService? permissionService;
  final ExceptionInterceptor? errorInterceptor;
  final bool installUncaughtErrorHandler;
  final String logTag;
  final void Function(XJet)? onInitialized;

  const XJetConfig({
    this.debug = false,
    this.autoDiscoverConfig = false,
    this.database,
    this.cache,
    this.eventBus,
    this.router,
    this.imageLoader,
    this.http,
    this.permissionService,
    this.errorInterceptor,
    this.installUncaughtErrorHandler = false,
    this.logTag = 'DartJet',
    this.onInitialized,
  });
}

/// DartJet 唯一入口，对应 Android XJet。
///
/// ```dart
/// XJet.init(XJetConfig(debug: true));
/// XJet.register<UserService>(UserService, userImpl);
/// final cache = XJet.cache();
/// ```
class XJet {
  XJet._();

  static final XJet instance = XJet._();
  static SpiRegistry? _registry;
  static RouteRegistry _routes = RouteRegistry();
  static bool _initialized = false;
  static XJetConfig? _config;
  static SpiConfig _spi = SpiConfig();

  static bool get isInitialized => _initialized;

  static XJetConfig? get config => _config;

  static RouteRegistry get routes => _routes;

  static SpiConfig get spi => _spi;

  /// 初始化：显式 config → 内置默认 → onInitialized。
  static void init(XJetConfig config) {
    if (_initialized) return;
    _initialized = true;

    XJetLog.init(enabled: config.debug, logTag: config.logTag);

    final reg = SpiRegistry();
    _routes = RouteRegistry();
    _spi = SpiConfig();

    // 1) 显式程序化配置最高优先
    if (config.cache != null) {
      reg.register<CacheProvider>(CacheProvider, config.cache!, override: true);
    }
    if (config.eventBus != null) {
      reg.register<EventBusProvider>(EventBusProvider, config.eventBus!,
          override: true);
    }
    if (config.http != null) {
      reg.register<HttpProvider>(HttpProvider, config.http!, override: true);
    }
    if (config.imageLoader != null) {
      reg.register<ImageLoaderProvider>(ImageLoaderProvider,
          config.imageLoader!,
          override: true);
    }
    if (config.router != null) {
      reg.register<RouterProvider>(RouterProvider, config.router!,
          override: true);
    }
    if (config.permissionService != null) {
      reg.register<PermissionService>(PermissionService,
          config.permissionService!,
          override: true);
    }
    if (config.errorInterceptor != null) {
      reg.register<ExceptionInterceptor>(ExceptionInterceptor,
          config.errorInterceptor!,
          override: true);
    }
    if (config.database != null) {
      reg.register<DatabaseProvider>(DatabaseProvider, config.database!,
          override: true);
    }

    // 2) 内置默认兜底
    if (!reg.has(CacheProvider)) {
      reg.register<CacheProvider>(CacheProvider, InMemoryCacheProvider());
    }
    if (!reg.has(EventBusProvider)) {
      reg.register<EventBusProvider>(EventBusProvider, XJetEventBus());
    }
    if (!reg.has(HttpProvider)) {
      reg.register<HttpProvider>(HttpProvider, DartHttpProvider());
    }
    if (!reg.has(DatabaseProvider)) {
      reg.register<DatabaseProvider>(
          DatabaseProvider, InMemoryDatabaseProvider());
    }
    if (!reg.has(PermissionService)) {
      reg.register<PermissionService>(
          PermissionService, GrantedPermissionService());
    }
    if (!reg.has(ExceptionInterceptor)) {
      reg.register<ExceptionInterceptor>(
          ExceptionInterceptor, LogExceptionInterceptor());
    }

    _config = config;
    _registry = reg;
    config.onInitialized?.call(instance);
  }

  // ---- 注册 ----

  static void register<T>(Type api, T implementation, {bool override = false}) {
    _registry!.register<T>(api, implementation, override: override);
  }

  static void registerProvider<T>(Type api, ServiceProvider<T> provider,
      {bool override = false}) {
    _registry!.registerProvider<T>(api, provider, override: override);
  }

  static void override<T>(Type api, T implementation) =>
      register<T>(api, implementation, override: true);

  // ---- 查询 ----

  static T? getOrNull<T>(Type api) => _registry!.getOrNull<T>(api);

  static T get<T>(Type api) => _registry!.get<T>(api);

  static CacheProvider cache() => get<CacheProvider>(CacheProvider);
  static EventBusProvider eventBus() => get<EventBusProvider>(EventBusProvider);
  static RouterProvider router() => get<RouterProvider>(RouterProvider);
  static ImageLoaderProvider? imageLoader() =>
      getOrNull<ImageLoaderProvider>(ImageLoaderProvider);
  static HttpProvider http() => get<HttpProvider>(HttpProvider);
  static DatabaseProvider database() => get<DatabaseProvider>(DatabaseProvider);
  static PermissionService permission() =>
      get<PermissionService>(PermissionService);
  static ExceptionInterceptor errorInterceptor() =>
      get<ExceptionInterceptor>(ExceptionInterceptor);

  /// 上报全局拦截器，不重抛。
  static void capture(String source, Object error,
      {ErrorSeverity severity = ErrorSeverity.error}) {
    errorInterceptor().onError(source, error, severity: severity);
  }

  // ---- 网络便捷 ----

  static Future<HttpResponse> getText(String url,
      {Map<String, String> headers = const {}}) {
    return http()
        .execute(HttpRequest(method: 'GET', url: url, headers: headers));
  }

  static Future<HttpResponse> postJson(String url, String json,
      {Map<String, String> headers = const {}}) {
    final merged = {
      ...headers,
      'Content-Type': 'application/json; charset=utf-8'
    };
    return http().execute(HttpRequest(
        method: 'POST',
        url: url,
        headers: merged,
        body: Uint8List.fromList(utf8.encode(json))));
  }

  // ---- SPI 配置 ----

  /// 用 JSON 配置注册一批 SPI：`{"API_NAME":"FACTORY_NAME"}`。
  static List<Type> applySpiConfig(String json, {bool override = true}) {
    return _spi.loadJson(_registry!, json, override: override);
  }

  // ---- 路由 ----

  static void registerRoute(
    String path, {
    String group = 'app',
    String title = '',
    bool override = false,
  }) {
    _routes.register(
        RouteDescriptor(path: path, group: group, title: title),
        override: override);
  }
}
