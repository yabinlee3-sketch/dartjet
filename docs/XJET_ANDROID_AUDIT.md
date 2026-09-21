# XJet Android 源码审计（Phase 0）

版本审计对象：仓库 `xjet/` 下的 Android XJet（当前 README 标为 2.2.1）。
审计方式：实际阅读源码文件，不是只看 README。

## 1. 总体定位

- 单一 `xjet` AAR，单依赖即可使用。
- MVVM-first：`View → XViewModel → XRepository → Provider/DataSource`。
- 核心原则：**framework owns the contract, ecosystem owns the implementation**。
- 无注解处理器，注册全部运行时完成（代码注册 / config asset / 路由表）。
- 仓库内 `xjet` 模块是唯一实现；`xjet-app`、`xjet-news-demo` 是两套真实使用示范；`xjet-core/xjet-spi/xjet-room/...` 目前为空壳（历史拆分后已合并）。

## 2. 全局入口 XJet（core/XJet.kt）

- `XJet.init(context, XJetConfig)`：幂等，只初始化一次。
- 注册：`register(api, impl, override)`、`registerProvider(api, factory, override)`、`override(api, impl)`。
- 查询：`getOrNull(api)`、`get(api)`、类型化快捷方法：
  - `database()`、`cache()`、`eventBus()`、`router()`、`imageLoader()`、`http()`、`errorInterceptor()`。
- 异常：`capture(source, throwable, severity)`、`tryCatch(source, block)`。
- 路由：`routes()`、`registerRoute(path, targetActivity, group, title, override)`、`open(Activity) {}`。
- 初始化顺序：
  1. config 显式 provider（override=true，最高优先）
  2. 内置默认实现（Cache / EventBus / Router / Http / ImageLoader / ExceptionInterceptor，仅缺省注册）
  3. config asset 自动发现（`assets/xjet/spi.properties`，override=true）
  4. 可选安装 uncaught 错误处理器
  5. 回调 `config.onInitialized()`

## 3. XJetConfig（core/XJetConfig.kt）

字段：`debug`、`autoDiscoverConfig`、`spiAssetPath`、`database`、`cache`、`eventBus`、`router`、`imageLoader`、`errorInterceptor`、`installUncaughtErrorHandler`、`logTag`、`onInitialized`，并提供 Builder。

## 4. Provider / SPI / Registry

- `ServiceProvider<T> { create(): T }`：懒工厂。
- `InstanceProvider`、`NewInstanceProvider`。
- `SpiRegistry`：
  - `register`（实例）、`registerProvider`（工厂）、`registerClass`（反射无参构造）
  - `getOrNull` / `get` / `has` / `unregister` / `keys` / `size`
  - 重复注册默认抛错，`override=true` 才替换
- `SpiConfigLoader`：`.properties` 文件 `API=IMPL`，反射注册。
- 注解 `@SpiService`、`@XRoute` 保留在源码中，但当前工作流以运行时注册为主，README 也明确“不依赖 KSP”。

## 5. 核心 VM / 状态

- `XViewModel`（extends androidx ViewModel）：
  - 拥有唯一 `uiState: StateFlow<UiState>`（初始 Loading）
  - `setLoading / setError / setEmpty / setContent`
  - `refresh()`（受保护，默认 setLoading）+ `retry()`
  - `capture()`、`launchSafe(source, block)`、`collect(flow, onEach)`
- `UiState`：sealed `Loading / Error(message?) / Empty / Content`，四态统一定义，Compose 与 XML 共用。

## 6. Repository

- `XRepository`：
  - 暴露 `protected val xjet`
  - `capture(source, throwable)`（只上报不重抛）
  - `safe(source, block)`（先上报，再 rethrow）
- 不持有 Activity / Compose / ViewModel。

## 7. Provider 契约（core/Providers.kt）

- `CacheProvider`：String 与 bytes 的 put/get/remove/clear。
- `EventBusProvider`：`events(clazz)`、`stickyEvents(clazz)`、`post`、`postSticky`。
- `DatabaseProvider`：`dao(clazz)`、`transaction(block)`、`clearAllTables()`、`databaseName()`。
- `RouterProvider`：`navigate(route,args)`、`back()`、`currentRoute()`。
- `ImageLoaderProvider`：`load(url, ImageTarget)`；`ImageTarget.onLoadSuccess(bitmap)/onLoadFailed(error)`。
- `UiDelegate/XJetContent` 已标记 Deprecated / marker，仅遗留。

## 8. 默认实现（core/Defaults.kt、Net.kt、AndroidImageLoaderProvider.kt、RoomDatabaseProvider.kt）

- Cache：`InMemoryCacheProvider`、`SharedPrefsCacheProvider`、`FileCacheProvider`。
- EventBus：`SharedFlowEventBus`（once-off SharedFlow + sticky StateFlow）。
- Router：`SimpleRouterProvider`（Activity + Intent，args 支持 String/Int/Long/Boolean/StringList）。
- Http：`HttpRequest`、`HttpResponse(status/headers/body/isSuccess/bodyText)`、`HttpProvider` 契约、`JdkHttpProvider`（java.net HttpURLConnection，无第三方依赖）。
- ImageLoader：`AndroidImageLoaderProvider` + `ImageViewTarget`。
- Database：`RoomDatabaseProvider`（Room，DAO 缓存反射查找，transaction/clearAllTables）。

## 9. 路由

- `RouteDescriptor(path, group, title, targetClassName)`；`RouteRegistry` runtime map。
- `RouterBuilder`：`putString/putInt/putLong/putBoolean/putParcelable/putSerializable/putExtras/addFlags/requestCode/anim`，然后 `launch`。
- `XJet.open(target, context) {}` 链式导航。

## 10. 异常与日志

- `ErrorSeverity { INFO, WARNING, ERROR }`；`ExceptionInterceptor.onError(source, throwable, severity)`。
- `LogExceptionInterceptor` 默认 JUL 日志实现；`tryCatch` 扩展函数。
- `XJetLog`：debug/tag；`v/d/i/w/e`、`e(throwable)`、`json(xml)` 格式化打印。

## 11. 响应式工具（core/Flows.kt）

- `XJetDispatchers`（main/io/computation，可替换）。
- `XJet.scope()`：application-scoped supervisor + IO。
- `Flow.collectIn(owner, minState)`：生命周期内收集。
- `OneShotEvent<T>`：一次性事件。
- `Flow.catchAndReport(source)`：异常上报后不死。

## 12. UI 双体系

- Compose：`XJetTheme`、`XJetStateBox(state, loading,error,empty,content)`、`NavGraphBuilder.xJetComposeRoutes`、`OneShotEvent.collectAsEffect`。
- XML：`XJetActivity<VM>`（生命周期 STARTED 时收集 uiState）、`setUiState(state, loading,error,empty,content,onError)`、`XJetXmlUiDelegate`（Deprecated）、`SimpleRecyclerAdapter<T, VH>`（setData/addData/clearData/item/data/onClick）。

## 13. 工具

- `Kits`：randomString/randomInt/isToday/formatDate/makeDirs/file helpers/packageName/versionName/versionCode/deleteRecursively。
- `Codec`：md5/sha1/sha256 hex。
- `PermissionKit`：areGranted/missing/launch/shouldShowRationale。

## 14. 真实使用示范

- `xjet-app`：Application 注册 GreetingService + 路由 + Room + init；MainActivity Compose Home / HomeViewModel / GreetingRepository；XmlActivity 走 `setUiState`；assets/xjet/spi.properties 演示 config asset 注册。
- `xjet-news-demo`：新闻列表演示。App 注册 `newsDetail` 路由；NewsViewModel 持有四态 + items；NewsRepository 用 `XJet.getText` 拉 Hacker News，失败/无网络用 SampleNews 兜底；NewsList/Detail 均为 Compose + XJetStateBox。
- 测试：`SpiRegistryTest`（register/get、重复注册需 override、config loader 反射、unregister）、`ExceptionInterceptorTest`（tryCatch 上报、返回值、LogInterceptor）。

## 15. 需要迁移到 Flutter 的职责清单

1. 单入口 `XJet` + `XJetConfig` + `init/register/override/get`
2. `XViewModel`（生命周期/异步/四态/错误捕获）
3. `UiState` 四态
4. `XRepository`
5. Provider 契约：Cache/EventBus/Database/Router/ImageLoader/ExceptionInterceptor
6. SPI Registry + ServiceProvider（懒工厂）+ override
7. Network（Request/Response/Provider/默认实现，业务不暴露底层）
8. Router + RouteRegistry（path/args）
9. EventBus（once-off + sticky）
10. 全局异常捕获（含错误处理渠道）
11. 结构化日志 XJetLog
12. 缓存三级默认（内存/持久/文件）
13. Database 抽象 + 默认实现（可替换）
14. 图片加载抽象 + 默认实现
15. 权限工具
16. Lists（Flutter 无 RecyclerView，做成 XListView/DataSource + 分页）
17. 快速开发体验（Page → ViewModel → Repository → Network）

