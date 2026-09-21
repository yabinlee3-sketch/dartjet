import 'dart:async';
import 'package:flutter/foundation.dart';
import 'x_jet.dart';

/// 一次性事件，对应 Android OneShotEvent。
/// 使用 sync 广播流，不重放历史事件。
class OneShotEvent<T> {
  final StreamController<T> _controller =
      StreamController<T>.broadcast(sync: true);

  void emit(T value) {
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  Stream<T> asStream() => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

/// 流异常上报后继续，对应 Android Flow.catchAndReport。
extension CatchAndReport<T> on Stream<T> {
  Stream<T> catchAndReport(String source) =>
      handleError((Object e, StackTrace st) => XJet.capture(source, e));
}

/// 调度器占位。Dart/Flutter 没有可注入的 Dispatch，保留概念用于测试替换。
@immutable
class XJetDispatchers {
  final bool debug;
  const XJetDispatchers({this.debug = true});
}
