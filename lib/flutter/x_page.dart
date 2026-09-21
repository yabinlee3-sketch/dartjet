import 'package:flutter/widgets.dart';
import '../core/x_view_model.dart';

/// 页面基类，对应 Android XJetActivityVM。
/// 负责 ViewModel 生命周期绑定与四态刷新。
abstract class XPage<VM extends XViewModel> extends StatefulWidget {
  const XPage({super.key});

  VM createViewModel(BuildContext context);
}

abstract class XPageState<VM extends XViewModel> extends State<XPage<VM>> {
  VM? _vm;
  bool _boundsChecked = false;

  VM get viewModel {
    final vm = _vm;
    if (vm == null) {
      throw StateError('ViewModel 尚未初始化，请在 didChangeDependencies 之后访问。');
    }
    return vm;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_boundsChecked) {
      _boundsChecked = true;
      _vm = widget.createViewModel(context);
      _vm!.addListener(_onViewModelChanged);
    }
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  void navigate(String route, [Map<String, Object?> args = const {}]) {
    final entry = XJetRouterScope.maybeOf(context);
    if (entry != null) {
      entry.navigate(route, args);
    }
  }

  @override
  void dispose() {
    final vm = _vm;
    if (vm != null) {
      vm.removeListener(_onViewModelChanged);
      vm.dispose();
    }
    _vm = null;
    super.dispose();
  }
}

/// 让 XPage 能拿到全局 Router 的轻量 InheritedWidget 桥梁。
/// 仅作为路由结合时的便利，非必须。
class XJetRouterScope extends InheritedWidget {
  final void Function(String route, Map<String, Object?> args) _navigate;
  const XJetRouterScope({
    super.key,
    required void Function(String route, Map<String, Object?> args) onNavigate,
    required super.child,
  }) : _navigate = onNavigate;

  static XJetRouterScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<XJetRouterScope>();

  void navigate(String route, Map<String, Object?> args) =>
      _navigate(route, args);

  @override
  bool updateShouldNotify(XJetRouterScope oldWidget) => false;
}



