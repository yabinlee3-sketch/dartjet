# DartJet 新闻 Demo（目录骨架说明）

这个示例的 `lib/` 包结构刻意按 **XDroid 官方 Demo（`cn.droidlover.xdroidmvp.demo`）** 的归类方式来组织，
和 Android `xjet-news-demo` 使用同一套骨架，方便你在三端之间迁移时不用重新想目录。

## 目录对照

| XDroid Demo 目录 | DartJet 示例目录 | 放什么 |
| --- | --- | --- |
| `App.java` | `lib/main.dart` + `lib/app/news_app.dart` | 入口 + 应用装配（初始化 XJet、注册路由） |
| `kit/AppKit.java` | `lib/kit/news_kit.dart` | 应用级常量 / 路由信息 / 接口地址 |
| `model/` | `lib/model/news_item.dart` | 数据模型 |
| `net/Api.java + GankService.java` | `lib/net/` | 数据仓库（网络 + Repository + 离线兜底 + 本地 DAO） |
| `present/PBasePager.java` | `lib/present/news_view_model.dart` | 页面状态控制器（MVVM 的 ViewModel） |
| `ui/` | `lib/ui/` | 页面（列表页、详情页） |
| `adapter/HomeAdapter.java` | `lib/adapter/news_card.dart` | 列表项组件 |
| `widget/StateView.java` | 框架自带 `XStateBox` | 四态/通用 UI，不需要手写 |

## 推荐新增业务的做法

- 加一个页面：在 `ui/` 放 `XxxPage`，在 `present/` 放 `XxxViewModel`。
- 加一个接口/数据源：在 `net/` 加 Repository，在 `model/` 加对应 Model。
- 列表页复用：在 `adapter/` 加列表项组件。
- 应用级常量/工具：放 `kit/`。

这样“页面 → 状态 → 数据 → 模型”的入口是固定的，新业务直接往对应目录填即可。
