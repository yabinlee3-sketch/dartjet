import 'package:flutter/foundation.dart';
import 'ui_state.dart';
import 'x_jet.dart';

/// MVVM 状态基类，对应 Android XViewModel。
/// 唯一四态 uiState + 业务子类通过 ValueNotifier 暴露数据。
abstract class XViewModel extends ChangeNotifier {
  final ValueNotifier<UiState> _uiState;
  bool _disposed = false;

  XViewModel() : _uiState = ValueNotifier<UiState>(const UiStateLoading());

  /// 页面四态，View 通过它渲染 loading/error/empty/content。
  ValueListenable<UiState> get uiState => _uiState;

  /// View 请求重试。Error 态下先强制回到 Loading。
  void retry() {
    refresh();
    if (_uiState.value is UiStateError) {
      setLoading();
    }
  }

  /// 子类可重写为真正的加载逻辑；默认只切到 Loading。
  @protected
  void refresh() {
    setLoading();
  }

  @protected
  void setLoading() {
    _uiState.value = const UiStateLoading();
    _notify();
  }

  @protected
  void setError(Object error, {String? message}) {
    _uiState.value = UiStateError(
        message ?? (error is Error ? error.toString() : '$error'));
    capture('vm:$runtimeType', error);
  }

  @protected
  void setEmpty() {
    _uiState.value = const UiStateEmpty();
    _notify();
  }

  @protected
  void setContent() {
    _uiState.value = const UiStateContent();
    _notify();
  }

  /// 上报全局拦截器，不重抛。
  @protected
  void capture(String source, Object error) {
    XJet.capture(source, error);
  }

  /// 安全启动异步任务：失败上报并切 Error 态，不重抛。
  Future<void> launchSafe(String source, Future<void> Function() block) async {
    try {
      await block();
    } catch (e) {
      capture(source, e);
      setError(e);
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _uiState.dispose();
    super.dispose();
  }
}
