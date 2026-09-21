# DartJet

以 Android XJet 为唯一架构母本的 Flutter/Dart 快速开发框架。

> framework owns the contract, ecosystem owns the implementation.


> GitHub：https://github.com/yabinlee3-sketch/dartjet

## 已补齐能力（Phase 1 完成）

- 默认数据库：InMemoryDatabaseProvider（DAO 工厂注册 + 表记录）
- 权限服务：PermissionService + GrantedPermissionService 默认
- SPI 配置：SpiConfig 工厂白名单 + XJet.applySpiConfig(json)
- 全局错误：
unZonedGuarded + FlutterError.onError + PlatformDispatcher.onError
- 新闻 Demo：列表/详情/重试/离线兜底/**收藏写入数据库表**
## 特性

- 单一包、单一入口：`XJet.init / register / override / get`
- MVVM 四态：`XViewModel` + `UiState`（Loading/Error/Empty/Content）
- `XRepository` 数据层基类
- Provider / SPI 注册表，默认实现可替换
- 网络/缓存/事件/日志/错误处理统一抽象
- 路由：`RouteRegistry` + `RouterProvider`
- 列表：`ListDataSource` + `XListView`
- 页面基座：`XPage` + `XJetStateBox`
- 新闻 Demo：列表/详情/重试/离线兜底

## 快速开始

依赖：

```yaml
dependencies:
  dart_jet:
    path: ../dartjet
```

初始化：

```dart
import 'package:dart_jet/dart_jet.dart';

void main() {
  XJet.init(
    XJetConfig(
      debug: true,
      logTag: 'MyApp',
      installUncaughtErrorHandler: true,
    ),
  );
  xJetRunApp(const MyApp());
}
```

创建页面：

```dart
class HomePage extends XPage<HomeViewModel> {
  const HomePage({super.key});

  @override
  HomeViewModel createViewModel(BuildContext context) => HomeViewModel();

  @override
  State<XPage<HomeViewModel>> createState() => _HomePageState();
}

class _HomePageState extends XPageState<HomeViewModel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: XJetStateBox(
        state: viewModel.uiState.value,
        content: const Text('内容就绪'),
      ),
    );
  }
}
```

创建 ViewModel：

```dart
class HomeViewModel extends XViewModel {
  void load() {
    setLoading();
    launchSafe('home.load', () async {
      // 业务逻辑
      setContent();
    });
  }
}
```

注册与替换 Provider：

```dart
XJet.register<CacheProvider>(CacheProvider, MyCache());
XJet.override<HttpProvider>(HttpProvider, MyHttp());
```

业务代码不允许直接 import Dio / GetX / Riverpod / Provider / BLoC / go_router / Hive / Isar / Drift 等第三方库；它们只能作为框架内部默认实现。

## 新闻 Demo

`example/` 是一个完整新闻 Demo：

```text
NewsListPage
   ↓ createViewModel
NewsViewModel（四态 + items）
   ↓
NewsRepository（Hacker News + SampleNews 离线兜底）
```

```bash
cd example
flutter run
```

## 文档

- `docs/XJET_ANDROID_AUDIT.md` —— Android XJet 源码审计
- `docs/XJET_FLUTTER_MAPPING.md` —— Android → Dart 映射
- `docs/XJET_FLUTTER_OPEN_QUESTIONS.md` —— 开放问题
- `docs/XJET_FLUTTER_ARCHITECTURE.md` —— 架构方案
- `docs/XJET_FLUTTER_PHASE1_PLAN.md` —— Phase 1 计划与验收

## 测试

```bash
flutter test
```

当前已通过：

- 核心契约测试（Registry / UiState / XJet init / override）
- Widget 测试（XJetStateBox / XListView / XPage）
- 新闻 Demo 测试（离线加载 / 错误态 / 详情页）

## 命名

DartJet = Dart + Jet，延续 XJet 的“Jet/快速上手”语义，同时明确这是 Dart/Flutter 实现，不再是“XJet Flutter”这个名字。
