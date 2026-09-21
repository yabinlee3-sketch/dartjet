import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/x_jet.dart';

/// DartJet 应用入口包装：安装全局错误处理器并运行 App。
void xJetRunApp(Widget app) {
  final config = XJet.config;
  if (config?.installUncaughtErrorHandler ?? false) {
    FlutterError.onError = (details) {
      XJet.capture('flutter', details.exception);
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      XJet.capture('platform', error);
      return true;
    };
  }
  runZonedGuarded(() {
    runApp(app);
  }, (Object e, StackTrace st) {
    XJet.capture('zone', e);
  });
}
