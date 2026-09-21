# DartJet Phase 1 实施计划（Phase 0 产物）

> 当前仅处于 Phase 0。本文是经过源码审计、映射与开放问题评估后的 Phase 1 执行计划。
> **Phase 1 需经用户确认后启动。**
> 每个递增都遵循：先测试（red→green）→ 实现 → `dart analyze`/`flutter test` 通过 → 文档同步。

## 0. 前置确认项（从 OPEN_QUESTIONS 收口）

进入 Phase 1 前，先和用户确认以下决策（默认值见括号）：

1. 状态机制：`ChangeNotifier + ValueListenable`（默认，不使用第三方状态库）。
2. 路由默认：`Navigator 1.0 + MaterialPageRoute`（默认；go_router 仅作为可选择适配层的替换实现）。
3. 数据库：`DatabaseProvider` 契约 + 默认实现方案（默认 sqflite 适配/DAO 工厂注册；如需 Drift 生成代码则改为 Drift 隐藏封装）。
4. 全局错误：提供 `XJet.runApp` 包装（默认）。
5. 权限/包信息：V1 用最小 method channel 还是 `permission_handler`/`package_info_plus`（默认 method channel，零第三方）。
6. asset SPI 发现：V1 不做反射资产发现，仅保留代码注册 + 默认注册（默认）。

## 1. 里程碑总览

```text
M1 脚手架         M2 Core 契约       M3 Provider 默认实现
M4 页面基座        M5 列表数据源       M6 新闻 Demo
M7 一致性验证       M8 收尾/发布
```

每个里程碑均要求测试通过、analyze 通过。

## 2. M1 脚手架

- 创建 `dartjet/` package：`pubspec.yaml`，name `xjet_flutter`，SDK >=3.x。
- 建立目录：`lib/core`、`lib/flutter`、`example/`、`test/`。
- `lib/xjet_flutter.dart` 聚合 export。
- 空 README（Phase 0 说明）；本目录工作区已有 `docs/`。
- 测试：`flutter test` 能跑通空测试；`dart analyze` 无错。

产出：可编译的包骨架。

## 3. M2 Core 契约

实现并测试（纯 Dart）：

1. `UiState` 四态 sealed 类。
2. `ServiceProvider` / `InstanceProvider` / `NewInstanceProvider`。
3. `SpiRegistry`：
   - register / getOrNull / get / has / keys
   - 重复注册默认抛错
   - override 替换
4. `XJetConfig`（含 debug/logTag/onInitialized/installUncaughtErrorHandler/可选 provider 字段）。
5. `XJet` 门面：
   - `init` 只初始化一次
   - 注册顺序：config 显式 → 内置默认 → onInitialized
   - `register/override/getOrNull/get` 与 `cache/eventBus/router/http/errorInterceptor` 快捷方法
   - `capture` 只上报不重抛
   - `tryCatch` 返回 null on failure
6. `XRepository`（`safe` 先上报后 rethrow、`capture`）。
7. `ExceptionInterceptor` + `LogExceptionInterceptor` + `ErrorSeverity`。

测试：
- `RegistryTest`（注册/查/覆盖/重复抛错）
- `XJetInitTest`（幂等、默认注册、config override）
- `InterceptorTest`（capture 回调、tryCatch 返回值）

## 4. M3 Provider 默认实现 + 网络/缓存/事件/日志/工具

1. 网络：`HttpRequest`/`HttpResponse`、`HttpProvider`、`DartHttpProvider`（用 `dart:io` 或 `package:http` 封装的决策决出）、`XJet.getText/postJson`。
2. 缓存：`InMemoryCacheProvider`、`FileCacheProvider`。（`SharedPrefsCacheProvider` 视权限决策放入 M3 可选）
3. 事件：`XJetEventBus`（once-off 广播 + sticky）。
4. 日志：`XJetLog`（v/d/i/w/e/json/xml）。
5. 工具：`Kits`（随机/日期/文件简化版）、`Codec`（md5/sha1/sha256）。
6. 注册进 XJet 默认。

测试：
- 网络 fake（不访问生产站，用本地回应 mock/测试服务器）
- 缓存读写
- 事件 once/sticky
- 日志初始化
- 工具/编码

> 遵守限流红线：测试全部用本地 mock，不请求生产 API。

## 5. M4 页面基座（Flutter 层）

1. `XJetTheme`（Material 主题包装）。
2. `XJetStateBox`（四态容器，默认 loading/error/empty/content）。
3. `XPage<VM>`：
   - initState 创建 VM、绑定 uiState
   - dispose 解绑并 dispose VM
   - 支持 RouteObserver 暂停/恢复（V1 基础版）
   - 提供 `navigate/back`
4. `XJet.runApp` 包装：`runZonedGuarded` + `FlutterError.onError` 转发到 interceptor（当 config.installUncaughtErrorHandler=true）。
5. `RouterProvider` 默认实现 `MaterialRouterProvider` 与 `RouteRegistry`、`XJet.registerRoute`、`XJet.open(path,args)`。

测试：
- XJetStateBox 四态 Widget 测试
- XPage 生命周期测试（dispose 调用 VM.dispose）
- 路由注册/跳转（WidgetTester）

## 6. M5 列表数据源

1. `ListDataSource<T>`（setData/addData/clear，hasMore/loadingMore/loadMoreError）。
2. `XListView<T>`（监听数据源 + 底部加载触发）。
3. 接入 `XViewModel` 的分页状态机（可选泛型 `PagedXViewModel`）。

测试：
- 数据 source 状态切换
- 列表渲染与滚动到触发 loadMore

## 7. M6 新闻 Demo（对应 Android xjet-news-demo）

实现：

- `main.dart`：注册 `newsDetail` 路由、`XJet.init`。
- `NewsItem` 模型。
- `NewsRepository`：用 `XJet.getText` 拉 Hacker News topstories + item 详情；失败/断网时返回 `SampleNews`（离线兜底）。
- `NewsViewModel`：四态 + `items`；`loadRemote/loadSample/retry`。
- `NewsListPage`：`XPage` + `XJetStateBox` + `XListView`；错误页提供“重试联网”和“离线示例数据”按钮。
- `NewsDetailPage`：读取路由参数里的 `NewsItem` 展示标题/作者/分数/评论/链接，并提供打开链接按钮。

**不引入 Dio/getx/riverpod/go_router 等任何业务直连库。**

测试：
- ViewModel 状态流转（fake Repository，不请求真实网络）
- 列表页/详情页 Widget 测试（用 fake 数据）
- 离线兜底分支测试

## 8. M7 一致性验证

逐项执行 `XJET_FLUTTER_MAPPING.md` 的一致性检查清单：

- 名称/职责/依赖/生命周期/状态/Provider/Network/Router/Error/Cache/Database/List/Demo 逐项比较。
- 差异项写回 `XJET_FLUTTER_OPEN_QUESTIONS.md`，不允许静默改架构。
- 检查业务文件没有直接 import 禁止的第三方库（脚本扫描）。

## 9. M8 收尾 / 发布

- README 补全（快速上手 18 节）。
- docs 与 Phase 1 结果同步。
- `dart analyze` + `flutter test` 全绿。
- 按用户确认的发布方式生成可运行示例（本地 `flutter run` / 发布包）。
- 按 Definition of Done 检查并汇报。

## 10. 明确不做

- 不在 Phase 1 实现 GetX/Riverpod/BLoC/Clean Architecture。
- 不实现 asset 反射式 SPI 发现（留给 V1.5，若用户需要）。
- 不实现 Android Room DAO 反射对等物（改用 DAO 工厂/注册制）。
- 不引入业务可见的第三方库。
- 不删除 Provider/override/RouteRegistry 等核心思想。

## 11. 验收标准

Phase 1 完成时，现场必须做到：

1. `dart analyze` 0 错误。
2. `flutter test` 0 失败（覆盖：Registry、XJet init、Interceptor、Net、Cache、Event、XStateBox、XPage、ListDataSource、News VM/Page）。
3. Demo `example/` 可本地运行：列表加载、重试、离线兜底、详情页跳转、打开链接。
4. 业务层零直接依赖第三方状态/网络/路由/存储库。
5. 每项架构契约均有对应单元/Widget 测试覆盖。
6. docs 与 README 与实现一致。

