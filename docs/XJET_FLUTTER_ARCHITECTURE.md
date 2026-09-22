# DartJet 架构文档（Phase 0 设计稿）

> 目标：给出 Flutter 版 XJet 的完整架构，作为 Phase 1 实施蓝本。
> 性质：这是 **方案**，不是最终代码；不一致点一律回到 Android 源码与 `XJET_FLUTTER_OPEN_QUESTIONS.md` 裁决。
> 设计母本：单核心、单依赖、无注解处理器、运行时注册、四态 MVVM、Provider 可替换。

## 1. 总体架构

```text
业务层（只看到 XJet API）
  View / XPage / XJetStateBox / XListView
        │ 调用
        ▼
   XViewModel（四态 uiState + 业务 ValueListenable）
        │ 调用
        ▼
   XRepository（数据组合，不碰 UI）
        │ 调用
        ▼
  XJet Provider 契约（Cache/EventBus/Database/Router/Http/Image/Error/Log）
        │
        ├── 内置默认实现（纯 Dart / Flutter 适配）
        └── 第三方库（只能在默认实现内部）

核心铁律：framework owns the contract, ecosystem owns the implementation.
业务层绝不 import Dio/Riverpod/GetX/go_router/Hive/Isar/Drift 等。
```

## 2. 包结构与源码目录

```text
dartjet/                  # 单 package
├── pubspec.yaml
├── lib/
│   ├── xjet_flutter.dart      # 统一 export（业务 import 这一个入口即可）
│   ├── core/                  # 纯 Dart，可脱离 Flutter 单测
│   │   ├── xjet.dart              # XJet 门面
│   │   ├── xjet_config.dart       # XJetConfig + SpiConfigPaths
│   │   ├── ui_state.dart          # UiState 四态
│   │   ├── x_view_model.dart      # XViewModel
│   │   ├── x_repository.dart      # XRepository
│   │   ├── providers.dart         # 各 Provider 契约
│   │   ├── defaults.dart          # InMemoryCache/FileCache/EventBus/Router 默认
│   │   ├── registry.dart          # SpiRegistry
│   │   ├── service_provider.dart  # ServiceProvider/InstanceProvider
│   │   ├── exception_interceptor.dart
│   │   ├── net.dart               # HttpRequest/HttpResponse/HttpProvider
│   │   ├── router.dart / route_registry.dart
│   │   ├── log.dart               # XJetLog
│   │   ├── flows.dart             # OneShotEvent/catchAndReport/XJetDispatchers
│   │   ├── kits.dart
│   │   ├── codec.dart
│   │   └── spi_config.dart
│   ├── flutter/               # 需要 Flutter binding 的适配与 UI 网关
│   │   ├── x_page.dart            # XPage<VM> 生命周期基类
│   │   ├── x_jet_theme.dart
│   │   ├── x_state_box.dart
│   │   ├── x_list_view.dart
│   │   ├── list_data_source.dart
│   │   ├── image_provider.dart    # ImageLoaderProvider 默认实现
│   │   ├── permission_kit.dart
│   │   ├── app_wrapper.dart       # XJet.runApp / Zone / 错误接管
│   │   └── database_provider.dart # 数据库默认实现（方案见开放问题 Q4）
│   └── spi/                       # 可选 SPI 发现支持
├── example/                   # 新闻 Demo
│   ├── lib/
│   │   ├── main.dart                 # 入口（等价 App.java）
│   │   ├── app/news_app.dart         # 应用装配 + 根组件
│   │   ├── kit/news_kit.dart         # 常量 / 路由信息 / 接口地址
│   │   ├── model/news_item.dart      # 模型
│   │   ├── net/                      # 数据仓库 + 离线兜底 + 收藏 DAO
│   │   ├── present/news_view_model.dart  # ViewModel
│   │   ├── ui/                       # 列表页 / 详情页
│   │   └── adapter/news_card.dart    # 列表项组件
│   └── assets/sample_news.json （可选）
└── test/                      # 单测 + Widget 测试
```

包名建议：`xjet_flutter`。业务 `pubspec.yaml` 依赖它一个包即可。

## 3. 初始化流程（保持 Android 顺序）

```text
XJet.init(config)
  1) 显式 config provider 注册（override=true）
  2) 内置默认实现缺省注册（Cache/EventBus/Router/Http/Image/Error）
  3) config 资产/配置发现（V1 可关闭，见 Q8）
  4) 可选安装全局错误处理（FlutterError/Zone）
  5) onInitialized()
```

显式配置示例：

```dart
XJetConfig(
  debug: true,
  installUncaughtErrorHandler: true,
  logTag: 'XJetNews',
  cache: SharedPrefsCacheProvider(...),   // 可选
  http: DioHttpProvider(...),             // 可选（被框架包住，业务不可见）
  imageLoader: CachedImageLoaderProvider(...),
  router: MaterialRouterProvider(...),
);
```

## 4. 状态流

### 4.1 四态

```dart
sealed class UiState {}
final class UiStateLoading extends UiState {}
final class UiStateError extends UiState { final String? message; }
final class UiStateEmpty extends UiState {}
final class UiStateContent extends UiState {}
```

### 4.2 XViewModel

```dart
abstract class XViewModel extends ChangeNotifier {
  ValueListenable<UiState> get uiState;
  ValueListenable<bool> get busy;        // 可选辅助
  void retry();                          // Error 时强制 Loading 再 refresh
  @protected  void refresh();
  @protected  void setLoading();
  @protected  void setError(Object error, {String? message});
  @protected  void setEmpty();
  @protected  void setContent();
  @protected  Future<void> launchSafe(String source, FutureOr<void> Function() block);
  @protected  void capture(String source, Object error);
  @override   void dispose();
}
```

局部状态转换保证：

```text
Loading -> Content / Empty / Error
Error   -> retry -> Loading -> ...
```

`refresh` 默认只 `setLoading`，由子类重写具体加载逻辑；`retry` 保证 UI 先回到 Loading。

### 4.3 页面绑定

```dart
abstract class XPage<VM extends XViewModel> extends StatefulWidget { ... }

class XPageState<VM> extends State<XPage<VM>> with RouteAware {
  VM createViewModel();      // 子类负责
  void buildContent();       // 子类提供内容

  initState:  _vm = createViewModel(); _listener = _onUiState;
  didChangeDependencies: 注册 RouteObserver（可暂停）;
  dispose:  _vm.removeListener; _vm.dispose;
}
```

`XJetStateBox` 直接消费 `uiState`：

```dart
XJetStateBox(
  state: vm.uiState,
  loading: ..., error: ..., empty: ..., content: ...,
)
```

## 5. Provider / SPI

### 5.1 Registry

```dart
class InstanceProvider<T> implements ServiceProvider<T> {
  InstanceProvider(this.instance);
  T create() => instance;
}

class SpiRegistry {
  final Map<Type, ServiceProvider<Object>> _providers = {};

  void register<T>(Type api, T instance, {bool override = false});
  void registerProvider<T>(Type api, ServiceProvider<T> provider, {bool override = false});
  T? getOrNull<T>(Type api);
  T get<T>(Type api);
  bool has(Type api);
  UnmodifiableListView<Type> keys();
}
```

重复注册：默认抛错；`override=true` 可替换。

### 5.2 Provider 契约

```dart
abstract class CacheProvider { String? get(key); void put(key,value); Uint8List? getBytes(key); void putBytes(...); void remove(key); void clear(); }
abstract class EventBusProvider { Stream<T> events<T>(); Stream<T> stickyEvents<T>(); Future<void> post(Object event); Future<void> postSticky(Object event); }
abstract class DatabaseProvider { T dao<T>(Type daoType); Future<T> transaction<T>(Future<T> Function() block); Future<void> clearAllTables(); String databaseName(); }
abstract class RouterProvider { void navigate(String route, Map<String,Object?> args); void back(); String? currentRoute(); }
abstract class HttpProvider { Future<HttpResponse> execute(HttpRequest request); }
abstract class ImageLoaderProvider { void load(String url, XImageTarget target); }
```

### 5.3 默认实现（V1 内置，均可 override）

| Provider | 默认实现 | 说明 |
|---|---|---|
| Cache | `InMemoryCacheProvider` | 内存 map |
| __   | `FileCacheProvider` | 目录文件 + 安全文件名 |
| __   | `SharedPrefsCacheProvider` | 可选（Flutter 适配） |
| EventBus | `XJetEventBus` | broadcast Stream + sticky map |
| Http | `DartHttpProvider` | `dart:io` / `package:http` 封装 |
| Router | `MaterialRouterProvider` | Navigator.push + RouteRegistry |
| Image | `DartImageLoaderProvider` | NetworkImage + 内存/磁盘缓存 |
| Error | `LogExceptionInterceptor` | FlutterLog/dart:developer |
| Database | 见开放问题 Q4 | 默认抽象存在，实现 Phase 1 决策 |

## 6. 网络

```dart
class HttpRequest {
  String method; String url; Map<String,String> headers; Uint8List? body;
  int connectTimeoutMillis; int readTimeoutMillis;
}
class HttpResponse {
  int status; Map<String,List<String>> headers; Uint8List body;
  String get bodyText; bool get isSuccess;
}
```

业务使用：

```dart
final resp = await XJet.instance.getText(url, headers: {...});
if (!resp.isSuccess) throw StateError('HTTP ${resp.status}');
```

JSON 解析由业务层或 Repository 用 `dart:convert` 处理，不引入额外库依赖。

## 7. 路由

```dart
class RouteDescriptor { String path; String group; String title; }
class RouteRegistry {
  void register(RouteDescriptor d, {bool override});
  RouteDescriptor? resolve(String path);
  List<RouteDescriptor> all(); List<RouteDescriptor> byGroup(String group);
  bool has(String path); void clear();
}

class MaterialRouterProvider implements RouterProvider {
  final RouteRegistry registry;
  final Map<String, PageRoute Function(Map<String,Object?> args)> pageBuilders;

  void navigate(route, args) {
    final builder = pageBuilders[route] ?? throw UnknownRoute(route);
    Navigator.push(context, builder(args));
  }
  void back() => Navigator.maybePop(context);
  String? currentRoute() => ModalRoute.of(context)?.settings.name;
}
```

`XJet.registerRoute(path, title, group, builder)` 提供注册页面的便利，业务不直接碰 Navigator。

## 8. 列表

```dart
class ListDataSource<T> extends ChangeNotifier {
  List<T> items;
  bool hasMore;
  bool loadingMore;
  Object? loadMoreError;

  void setData(List<T> data); void addData(List<T> data); void clear();
}

class XListView<T> extends StatelessWidget {
  final ListDataSource<T> source;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final VoidCallback? onLoadMore;   // 滚动到底部时触发
  ...
}
```

分页语义由 ViewModel 状态机 + Repository 决定，与 Android `SimpleRecyclerAdapter` 的 `setData/addData/clearData` 对齐。

## 9. 错误与日志

- `ErrorSeverity { info, warning, error }`
- `ExceptionInterceptor.onError(source, error, severity)`
- `XJet.capture(source, error, severity)`：只上报，不重抛
- `XRepository.safe(source, block)`：先上报后 rethrow
- `XJetLog`：`v/d/i/w/e/json/xml`
- 全局接管：
  - `XJetConfig.installUncaughtErrorHandler=true` 时，用 `XJet.runApp` 包装 `runZonedGuarded`；
  - 覆盖 `FlutterError.onError`；
  - `PlatformDispatcher.instance.onError` 转发到同一条 interceptor。

## 10. 生命周期

`XPage` 是唯一页面基类：

```text
initState:           创建 VM、绑定 uiState listener
didChangeDependencies: 注册 RouteAware、按需挂起/恢复
build:               读取 uiState + 业务状态渲染
dispose:             解绑 listener、dispose VM
```

Repository/Service 不做页面级状态，只有全局可替换实现。

## 11. 业务层红线（回归时必须检查）

1. 业务文件不 import `package:dio`、`package:provider`、`package:riverpod`、`package:bloc`、`package:go_router`、`package:hive`、`package:isar`、`package:drift`。
2. 业务只通过 `XJet.*` / `XViewModel` / `XRepository` 拿能力。
3. 第三方库只出现在 `lib/flutter/` 或 `lib/core/defaults/` 内。
4. ViewModel 不持有 BuildContext；Repository 不持有页面。
5. 任何把职责合并进一个类的改动都禁止。

## 12. 测试策略

- 纯 Dart 测试（`test/core/`）：Registry、UiState 状态转换、Http 默认实现的 fake、Cache、EventBus、Codec、Repository fake。
- Flutter Widget 测试（`test/flutter/`）：XJetStateBox 四态渲染、XListView 渲染/分页、XPage 绑定与 dispose、News Demo 列表/详情路由。
- 运行命令：
  - `dart analyze`
  - `flutter test`
  - `flutter build apk`（示例，可选）
- Definition of Done 见第 46 节：代码完成、测试通过、Demo 可运行、API 有文档、错误可恢复、架构契约不破坏、业务无硬依赖、Provider 可替换、关键行为有测试、docs 同步。

## 13. 架构自检

Phase 1 结束时按 `XJET_FLUTTER_MAPPING.md` 的一致性清单逐项打勾，并把无法对齐项写回 `XJET_FLUTTER_OPEN_QUESTIONS.md`。


