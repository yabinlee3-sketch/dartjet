# DartJet 开放问题（Phase 0）

> 本文记录 Android XJet 迁移到 Flutter 时无法 1:1 机械翻译的技术差异。
> 规则：**发现映射困难必须记录，不允许静默改架构**。
> 状态说明：每个问题给出“倾向方案 + 影响 + 待决策”。部分问题在 Phase 1 启动前需要确认，其余可在实现中按建议默认执行并在收尾时复核。

## Q1 响应式状态：ValueNotifier / ChangeNotifier / Stream

Android 侧：`uiState: StateFlow<UiState>` + 业务 `StateFlow`（collect in lifecycle）。

Flutter 映射难度：Dart 没有 StateFlow；`Stream` 与 `ValueListenable` 能力不同。

- 选项 A（建议）：`XViewModel extends ChangeNotifier`，内部 `ValueNotifier<UiState> _uiState`，对外暴露 `ValueListenable<UiState>`；业务状态同理用 `ValueListenable<T>`。优点：Widget 用 `ValueListenableBuilder`/`AnimatedBuilder` 即可，零第三方依赖，dispose 语义清晰。
- 选项 B：`Stream` + `StreamBuilder`，逻辑贴近现在 Android 使用者，但每次重建和订阅管理更繁琐。
- 选项 C：Riverpod/BLoC——被本项目明确禁止直接暴露给业务，除非藏在框架内，不推荐。

待决策：Phase 1 启动时确认 A 作为方向（默认 A）。

## Q2 Flutter 生命周期 vs Android Lifecycle

Android：`collectIn(owner, minState=STARTED)`；XJetActivity 在 STARTED 时才收集。

Flutter：Widget 只有 initState/didChangeDependencies/dispose；页面被覆盖时 `RouteAware.didPushNext/didPopNext` 可感知，但严格等价 STARTED 需要 route observer。

- 建议：`XPage` 内部统一处理：initState 绑定、dispose 解绑；若需要 pause 收集，用 `RouteObserver`（`didPushNext`/`didPopNext`）挂起/恢复收集。
- 影响：对简单 Demo 无感知，但框架语义要保持“页面不可见时不更新 UI 状态”的能力。
- 待决策：是否在 V1 就接入 RouteObserver 实现暂停/恢复（建议接入，工作量小）。

## Q3 路由：Navigator 1.0 vs go_router

Android：`SimpleRouterProvider` 用 Intent + RouteRegistry；`XJet.open` 提供链式参数。

Flutter：Navigator 是核心能力；go_router 更现代但不是框架必须。

- 选项 A（建议）：`RouterProvider` 内部使用 `MaterialPageRoute` + Navigator.push，参数通过 `RouteDescriptor.args` 编码；不引入 go_router，保持核心零依赖、更贴合 XJet 自己的 RouteRegistry。
- 选项 B：内部用 go_router 受 XJet 适配层隐藏，业务无感；但增加第三方依赖（仍不被业务看到）。
- 待决策：Phase 1 默认选 A；若用户有 URL/深链需求可改 B。

## Q4 数据库 DAO：Dart 无反射

Android：`RoomDatabaseProvider.dao(clazz)` 通过反射在 Database 子类上查找 getter。

Flutter/Dart：没有运行时反射；`Type` 无法像 `Class` 一样找到 accessor，DAO 天然需要手写 repository/query 方法。

- 建议：`DatabaseProvider` 契约改为“数据库实例 + 表/仓库注册”，默认实现提供：
  - 轻量 KV/表驱动 ORM（如 sqflite 适配）隐藏在下层；
  - 或 `dao<T>()` 由默认实现内部用 `Map<Type, dynamic>` 维护 DAO 单例（框架注入 DAO 工厂，而不是反射）。
- 影响：业务仍是 `XJet.database().dao<T>()`，但 **T 的获取方式和 Android 不同**（需要注册 DAO 工厂或生成的库生成代码）。
- 待决策：V1 默认实现方案、是否引入 Drift（可生成代码）vs 手写 sqflite 封装。

## Q5 图片加载返回值

Android：`ImageTarget.onLoadSuccess(bitmap)`。

Flutter：没有 Bitmap，图片渲染载体是 `ImageProvider` / `Widget`。

- 建议：`XImageTarget.onLoadSuccess(ImageProvider image)`，并提供便捷 `XNetworkImage`/`XImage` widget 包住加载流程；`ImageLoaderProvider` 先保持“URL → ImageProvider”语义，由默认实现用 `NetworkImage` + 磁盘缓存。
- 影响：业务层看不到底层实现，但“目标回调”形态需要从 bitmap 调整为 widget/imageProvider。
- 待决策：不需要额外确认，按上述建议执行并写入一致性检查。

## Q6 全局未捕获异常

Android：`XJetConfig.installUncaughtErrorHandler` 设置 Java 线程全局 handler，回调同一个 ExceptionInterceptor。

Flutter：错误来源有三类：`runZonedGuarded`（异步错误）、`FlutterError.onError`（构建/布局）、`PlatformDispatcher.instance.onError`（原生异常）。

- 建议：`XJetConfig.installUncaughtErrorHandler` 保留字段；init 时若开启，则：
  1. `FlutterError.onError = ` 上报 + 保留默认行为；
  2. `PlatformDispatcher.instance.onError = ` 上报；
  3. 若 XJet 参与 `runApp` 包装，则在 `runZonedGuarded` 统一接管。
- 影响：与 Android 一个 handler 处理所有异常的目标一致，只是入口分叉合并。
- 待决策：确认 XJet 是否提供 `XJet.runApp(...)` 便利包装（建议提供）。

## Q7 Kotlin Flow → Dart 流语义

Android：`Flow`（cold，结构化并发）、`SharedFlow`、`StateFlow`、`collectIn` 组合。

Flutter：`Stream`（single/broadcast）、`StreamController`、`ValueNotifier`。

- 建议：不追求 1:1 类名，而是保持语义：一次性事件 = `OneShotEvent`（broadcast Stream, sync, no replay）；连续状态 = ValueListenable；集合 = `ListDataSource`。
- 待决策：无；在架构文档中明确。

## Q8 Registry 键与配置发现

Android：`Class<T>`、候选有 `META-INF/xjet/spi.properties` 与 assets 文件、`NewInstanceProvider` 反射无参构造。

Dart：无 `Class`、无默认反射构造、资产文件读 `rootBundle` 需要 Flutter binding。

- 建议：
  - Registry 键用 `Type`；
  - `ServiceProvider<T>` 用 `T Function()` 工厂；
  - 资产文件发现改为“注册名 → 已注册工厂白名单”的模式（避免无反射实例化）。
- 待决策：V1 是否提供 asset discovery（建议 V1 提供代码内 `SpiConfigLoader` 简化版，资产发现列为 V1.5 可选）。

## Q9 权限与包信息

Android：`PermissionKit` 依赖 AndroidX + Activity；`Kits.packageName/versionName/versionCode` 依赖 PackageManager。

Flutter：需 platform channel 或第三方包（`permission_handler`、`package_info_plus`）。

- 建议：把这两个能力收敛为 `PermissionKit`/`Kits`，内部使用最小 platform channel 或把这些包作为可替换默认实现。
- 影响：业务看不到具体包；框架需要做平台插件依赖管理。
- 待决策：V1 是否引入 `permission_handler`/`package_info_plus`，还是写 method channel（建议 V1 写 method channel，零第三方依赖；或引入 package 作为默认实现）。

## Q10 `XJet.open` / Intent 参数

Android：`RouterBuilder.putParcelable/putSerializable/requestCode/anim`，支持复杂对象。

Flutter：Navigator 路由 args 需要可序列化或直接对象引用；无 Intent/startActivityForResult 对等物。

- 建议：`RouterProvider.navigate(route, args)`，参数允许 `Map<String, Object?>`；复杂对象通过 `XJet.register` 单例注册而非跨路由传 Parcelable。
- 影响：Demo 里 `NewsItem` 传详情页改为“详情页通过路由参数或通过注册表再次从 Repository 读取”，前者简单。
- 待决策：无，按此执行。

## Q11 列表分页/Adapter 语义

Android：`SimpleRecyclerAdapter.setData/addData/clearData`。

Flutter：`ListView.builder` 是惰性，但没有 Adapter 生命周期通知。

- 建议：`ListDataSource<T> extends ChangeNotifier` 暴露 `setData/addData/clear` + `hasMore/loadingMore/error`；`XListView` 监听它渲染；分页由 `loadMore` 回调与 ViewModel 协作。
- 待决策：V1 是否包含分页加载（建议包含基础分页，因列表是 Demo 核心）。

## Q12 双 UI 体系（Compose/XML）→ 单 Widget 体系

Android：Compose + XML 各一套，XJet 统一起来。

Flutter：只有一个 Widget 体系，不需要双套。

- 建议：用 `XPage` + `XJetStateBox` + `XListView` 作为“唯一 UI 网关”，这是合并而非删职责。
- 待决策：无。

## Q13 调度器

Android：`XJetDispatchers.main/io/computation` 可替换。

Flutter：主 isolate 是单线程事件循环；`compute` 处理 CPU 密集任务，IO 走异步 API。

- 建议：保留 `XJetDispatchers` 概念，但映射为 `main`（同步队列）与 `io`（Future/isolate 包装），`computation` 用 `compute()`。可替换注入用于测试。
- 待决策：无。

## Q14 测试环境

Android：JVM 单测 + Robolectric/espresso。

Flutter：`dart test` 纯逻辑测试 + `flutter test` Widget 测试。

- 建议：核心逻辑全部做成可无 Flutter 运行（不 import flutter），便于纯 Dart 测试；Widget 部分用 `flutter test`。
- 待决策：无。

## Q15 单包 vs 插件分包

Android：单一 `xjet` AAR。

Flutter：需要决定是否保持单一 `xjet_flutter` 包（含 platform code），还是拆 `core/`（纯 Dart）与 `flutter/`。

- 建议：发布单一 `xjet_flutter` 包；源码内部划分 `core/`（纯 Dart）与 `flutter/`（需要 Flutter binding），模拟源码模块但不拆发布包。
- 待决策：无。

## Q16 注解 `@SpiService` / `@XRoute`

Android：注解保留源码，但当前工作流运行时注册。

Flutter：Dart 注解不参与编译期代码生成，若不用 build_runner 就无价值。

- 建议：保留内部 `@XJetService`/`@XJetRoute` 仅作文档，实际流程用 `XJet.register/registerRoute` 运行时注册，不做代码生成。
- 待决策：无。

## Q17 已废弃 API（`UiDelegate` / `XJetContent`）

Android：已 Deprecated/marker。

- 建议：Flutter 版不实现这两个历史遗留；在一致性检查中明确“职责已经被 XPage/XJetStateBox 取代”。
- 待决策：无。

## 汇总：需要在 Phase 1 开始前由用户确认的问题

1. Q1 状态机制默认用 ChangeNotifier/ValueListenable（建议确认）。
2. Q3 路由默认 Navigator 1.0（建议确认；go_router 仅留可选）。
3. Q4 数据库默认实现方案（建议 V1 提供轻量 sqflite 适配并注册 DAO 工厂；如需 Drift 生成则确认）。
4. Q6 是否提供 `XJet.runApp` 全局包装（建议提供）。
5. Q9 权限/包信息默认实现用什么（建议先零第三方 method channel，后续可换）。
6. Q8 是否在 V1 提供资产文件式 SPI 发现（建议不提供，列为 V1.5）。

