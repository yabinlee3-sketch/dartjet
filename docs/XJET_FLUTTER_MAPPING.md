# DartJet 映射文档（Phase 0）

> 本文写于 Android XJet 源码逐文件审计之后（见 `XJET_ANDROID_AUDIT.md`）。
> 目标是：**Android 类 → Flutter 抽象 → 默认实现 → 可选第三方库 → 业务 API** 的一致映射。
> 规则：只改技术实现，不改职责与架构语义。

## 0. 映射总原则

1. 保持 XJet 的“框架定义契约、生态提供实现”。
2. 所有第三方库只能作为默认实现/适配层出现，业务层不得直接 import。
3. `XJet` 仍为唯一入口：`init / register / override / get / capture / open`。
4. 凡是 Flutter 生态心智与 XJet 冲突的地方，先保 XJet 语义，再选 Flutter 自然实现，并把无法 1:1 的部分记入 `XJET_FLUTTER_OPEN_QUESTIONS.md`。

## 1. 核心映射表

| Android XJet | 职责（Android 侧） | Flutter 抽象 | Flutter 默认实现 / 适配 | 业务层 API |
|---|---|---|---|---|
| `XJet`（object） | 唯一全局入口、注册/覆写/查询 | `XJet`（单例门面） | — | `XJet.init(config)`、`register/override/get/capture` |
| `XJetConfig`（data class + Builder） | 初始化配置 | `XJetConfig` | — | `XJetConfig(...)` |
| `SpiRegistry` | SPI 注册表，Type→Provider | `SpiRegistry`（`Map<Type, ServiceProvider>`） | — | `XJet.register` |
| `ServiceProvider<T>` | 懒工厂 | `ServiceProvider<T>` | `InstanceProvider`、`NewInstanceProvider` | 仅在框架内部使用 |
| `SpiConfigLoader` | 配置文件发现实现 | `SpiConfigLoader` | 运行期 `Map<String, ServiceProvider>` 或资产文件 | 仅框架内部 |
| `XViewModel` | 唯一四态 uiState + 异步+错误 | `XViewModel`（ChangeNotifier/共状态可观察） | 基类 | `setLoading/setContent/setError/setEmpty`、`retry()` |
| `UiState` | sealed 四态 | `UiState` sealed 类 | loading/error/empty/content | 页面渲染分支 |
| `XRepository` | 数据层基类 | `XRepository` | 基类 | `xjet`、`safe/capture` |
| `CacheProvider` | 缓存契约 | `CacheProvider` | `InMemoryCacheProvider`、`SharedPrefsCacheProvider`、`FileCacheProvider` | `XJet.cache()` |
| `EventBusProvider` | 事件总线契约 | `EventBusProvider` | `SharedFlowEventBus` 等价实现（广播 Stream + sticky） | `XJet.eventBus()` |
| `DatabaseProvider` | 数据库契约 | `DatabaseProvider` | 待定（Drift/sqflite/Isar 经适配层） | `XJet.database()` |
| `RouterProvider` | 导航契约 | `RouterProvider` | `NavigatorRouterProvider`（内部 Navigator） | `XJet.router()` |
| `RouteRegistry` | 路由表 | `RouteRegistry` | 运行期 Map | `XJet.routes()`、`registerRoute` |
| `HttpProvider` | 网络契约 | `HttpProvider` | `DartHttpProvider`（`dart:io` 或 `package:http` 包住） | `XJet.http()` |
| `HttpRequest`/`HttpResponse` | 不可变请求/响应 | 同名字段保持 | — | `XJet.getText/postJson` |
| `ImageLoaderProvider` | 图片加载契约 | `ImageLoaderProvider` | 默认下载器；返回 Widget/对应目标 | `XJet.imageLoader()` |
| `ExceptionInterceptor` | 全局异常拦截 | `ExceptionInterceptor` | `LogExceptionInterceptor` | `XJet.capture` |
| `XJetLog` | 结构化日志 | `XJetLog` | `dart:developer` debugPrint | `XJetLog.d/json/xml` |
| `XJetDispatchers` | 调度器可替换 | `XJetDispatchers` | 默认异步（main/io/compute） | 仅框架内部 |
| `collectIn` | 生命周期内收集 Flow | `XPage` 生命周期 + listener | `initState/addListener/dispose` | 页面自动绑定 |
| `OneShotEvent` | 一次性事件 | `OneShotEvent` | `StreamController.broadcast(sync)` | `emit/asStream` |
| `catchAndReport` | Flow 异常上报不死 | `catchAndReport` Stream 扩展 | — | 框架内部 |
| `Kits` | 工具函数 | `Kits` | `dart:math/io` 等 | 业务工具 |
| `Codec` | md5/sha1/sha256 | `Codec` | `crypto` 包隔离 | 业务工具 |
| `PermissionKit` | 权限工具 | `PermissionKit` | `permission_handler` 适配（或通道） | `XJet.permission()` |
| `XJetTheme` | Compose 主题 | `XJetTheme` | MaterialApp/ThemeData 包装 | 页面根 |
| `XJetStateBox` | Compose 四态容器 | `XJetStateBox` | StatelessWidget 分支 | 页面渲染 |
| `XJetActivity<VM>` | XML 基类 | `XPage<VM>` | StatefulWidget | 页面继承 |
| `SimpleRecyclerAdapter` | RecyclerView 适配 | `ListDataSource<T>` + `XListView` | `ListView.builder` | 列表页 |
| `RouteDescriptor` | 路由元数据 | `RouteDescriptor` | — | 路由表 |
| `RouterBuilder` | 链式 Intent 参数 | `XJet.open(path, args:...)` | Navigator 参数编码 | 页面跳转 |
| `getText/postJson` | 网络便捷扩展 | `XJet.getText/postJson` | — | Repository |

## 2. 关键类职责与 Flutter 落点

### 2.1 XJet 门面

Android：一个 `object`，所有能力走此入口。

Flutter 建议：

```dart
class XJet {
  XJet._();
  static XJet instance = XJet._();
  bool isInitialized;
  void init(XJetConfig config);
  T register<T>(Type api, T implementation, {bool override});
  T registerProvider<T>(Type api, ServiceProvider<T> provider, {bool override});
  T override<T>(Type api, T implementation);
  T? getOrNull<T>(Type api);
  T get<T>(Type api);
  // 快捷方法
  CacheProvider cache();
  EventBusProvider eventBus();
  RouterProvider router();
  HttpProvider http();
  ExceptionInterceptor errorInterceptor();
  // 错误
  void capture(String source, Object error, {ErrorSeverity severity});
}
```

### 2.2 XViewModel

Android 关键语义：

- `uiState` 是唯一四态 Flow，初始为 Loading。
- View 只订阅 uiState + 业务 StateFlow。
- `refresh/retry` 语义：retry 保证 Error 时回到 Loading。
- `launchSafe/collect` 捕获失败 -> `capture` + `setError`。

Flutter 落点：

- `XViewModel extends ChangeNotifier`（内部实现可用 `ValueNotifier<UiState>` 或单一 notifier）。
- 暴露 `ValueListenable<UiState> get uiState`；业务状态也建议不可变 `ValueListenable<T>`。
- `setLoading/setError/setEmpty/setContent`、`retry/refresh` 语义保持。
- `launchSafe` 用 `Future<void>` + `catch`；`collect` 用 `Stream.listen` 并在出错时上报。
- 生命周期由 `XPage` 负责 dispose；ViewModel 自身不持有 BuildContext。

### 2.3 UI 四态

```dart
sealed class UiState {}
class UiStateLoading extends UiState {}
class UiStateError extends UiState { final String? message; }
class UiStateEmpty extends UiState {}
class UiStateContent extends UiState {}
```

不取名 `UiState.Loading`（Dart 不支持同 sealed 下的静态内部类嵌套枚举），但保持四态语义一致。

### 2.4 Provider / SPI

Android 注册顺序（必须保持）：

1. 显式 config（override=true）
2. 内置默认（仅缺省注册）
3. config 资产（override=true）
4. 可选 uncaught 处理器
5. `onInitialized`

Flutter 差异：

- Dart 没有 `Class<T>`，用 `Type` 作为注册键。
- Dart 无法在无工厂时反射无参构造；`ServiceProvider<T>` 用闭包/普通函数。
- 版本 1 先做“运行时代码注册 + 内置默认”，资产文件发现作为 Phase 1 可选/后续项并记录。

### 2.5 网络

- `HttpRequest`/`HttpResponse` 字段保持不变（status/headers/body/bodyText/isSuccess）。
- 默认实现可以是 `dart:io HttpClient`，也可以把 `package:http` 包住（未定，见开放问题）。
- Repository 只调用 `XJet.getText/get/postJson`，不感知实现。

### 2.6 路由

- `RouteDescriptor(path/group/title/targetName)` 保留。
- `RouteRegistry.register/resolve/all/byGroup/has` 保留。
- `RouterProvider.navigate/back/currentRoute` 保留。
- Flutter 侧 `XPageRegistry` 用 `Map<String, PageBuilder>` 注册页面，避免反射 target class。
- `XJet.open(path, args:...)` 链式入口取代 `XJet.open(ActivityClass)`。

### 2.7 列表

Android `SimpleRecyclerAdapter<T>`：setData/addData/clearData/item/data/onClick。

Flutter：

```dart
class ListDataSource<T> extends ChangeNotifier {
  List<T> get items;
  void setData(List<T> data);
  void addData(List<T> data);
  void clear();
}

class XListView<T> extends StatelessWidget {
  // 监听 ListDataSource，内部用 ListView.builder
}
```

分页、加载更多在 Phase 1 由 `ListDataSource` + 底部状态补齐，职责仍是“列表容器 + 数据源”。

### 2.8 图片

- `ImageLoaderProvider.load(url, XImageTarget)`。
- `XImageTarget.onLoadSuccess(ImageProvider/Widget)/onLoadFailed`。
- 由于 Flutter 没有 BITMAP 对象，`onLoadSuccess` 返回 `ImageProvider` 或直接渲染 widget；具体接口见开放问题。

### 2.9 日志与错误

- `ErrorSeverity { info, warning, error }` 保留。
- `ExceptionInterceptor.onError(source, error, severity)` 保留。
- `LogExceptionInterceptor` 默认实现用 Flutter 日志输出。
- 全局 uncaught 落点：`runZonedGuarded` + `FlutterError.onError` 合并，映射到同一 `ExceptionInterceptor`。
- `XJetLog.json/xml` 保留缩进格式化。

## 3. Demo 映射（Android xjet-news-demo → Flutter example）

| Android Demo 文件 | Flutter example 对应 | 职责 |
|---|---|---|
| `NewsDemoApp.kt` | `main()` / `XJetApp` | 注册路由、init、install uncaught |
| `NewsListActivity.kt` | `NewsListPage`（XPage） | 列表页容器 |
| `NewsDetailActivity.kt` | `NewsDetailPage`（XPage） | 详情页容器 |
| `NewsListScreen` | `NewsListView` | UI 组合 |
| `NewsDetailScreen` | `NewsDetailView` | 详情 UI |
| `NewsViewModel` | `NewsViewModel` | 四态 + items |
| `NewsRepository` | `NewsRepository` | Hacker News + SampleNews 兜底 |
| `NewsItem` | `NewsItem` | 数据模型 |
| `SampleNews` | `SampleNews` | 离线示例数据 |

Demo 数据流保持不变：

```text
Page(XPage) -> NewsViewModel -> NewsRepository -> XJet.getText
   ↑                                              ↓
   └-------- uiState + items -------------------- HttpResponse
```

错误/重试/离线兜底行为也必须一致：错误页提供“重试联网”和“离线示例数据”两个按钮。

## 4. 一致性反向检查清单（Phase 1 收尾时逐项打勾）

- [ ] 名称对应：XJet/Config/UiState/XViewModel/XRepository/Provider/Route/Net/Cache/Event/Error/Log
- [ ] 职责对应：View 不碰数据源；VM 只暴露状态；Repo 不碰 UI
- [ ] 依赖对应：业务不直接 import 第三方状态/网络/路由/存储库
- [ ] 生命周期对应：XPage 负责绑/解绑；ViewModel dispose
- [ ] 状态对应：四态唯一
- [ ] Provider 对应：注册/override/get
- [ ] Network 对应：Request/Response/Provider/默认实现
- [ ] Router 对应：RouteRegistry + RouterProvider
- [ ] Error 对应：统一拦截器
- [ ] Cache 对应：内存/持久/文件三级
- [ ] Database 对应：抽象 + 默认实现
- [ ] List 对应：ListDataSource + XListView
- [ ] Demo 对应：列表/详情/重试/离线兜底

## 5. 结论

本映射文档确认 Android XJet 的架构契约可以在 Flutter 中 1:1 保真落地，除“无反射、无进程级 ViewModel/Activity、图片返回载体”等技术差异外，不需要改动职责边界。
具体不可机械翻译的部分已列入开放问题，不在本阶段静默改架构。

