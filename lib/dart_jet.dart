/// DartJet：以 Android XJet 为架构母本的 Flutter/Dart 快速开发框架。
///
/// 唯一导入入口。业务层只 import `package:dart_jet/dart_jet.dart`，
/// 不应直接 import 第三方状态/网络/路由/存储库。
library;

export 'core/codec.dart';
export 'core/database_defaults.dart';
export 'core/defaults.dart';
export 'core/exception_interceptor.dart';
export 'core/flows.dart';
export 'core/kits.dart';
export 'core/log.dart';
export 'core/net.dart';
export 'core/permission_service.dart';
export 'core/providers.dart';
export 'core/registry.dart';
export 'core/route_registry.dart';
export 'core/service_provider.dart';
export 'core/spi_config.dart';
export 'core/ui_state.dart';
export 'core/x_jet.dart';
export 'core/x_repository.dart';
export 'core/x_view_model.dart';

export 'flutter/app_wrapper.dart';
export 'flutter/image_provider.dart';
export 'flutter/list_data_source.dart';
export 'flutter/router_provider.dart';
export 'flutter/x_jet_theme.dart';
export 'flutter/x_list_view.dart';
export 'flutter/x_page.dart';
export 'flutter/x_state_box.dart';
