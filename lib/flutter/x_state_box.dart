import 'package:flutter/material.dart';
import '../core/ui_state.dart';

/// 四态容器，对应 Android Compose XJetStateBox / XML setUiState。
class XJetStateBox extends StatelessWidget {
  final UiState state;
  final Widget? loading;
  final Widget Function(BuildContext, String? message)? errorBuilder;
  final Widget? empty;
  final Widget content;

  const XJetStateBox({
    super.key,
    required this.state,
    this.loading,
    this.errorBuilder,
    this.empty,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case UiStateLoading():
        return Center(child: loading ?? const CircularProgressIndicator());
      case UiStateError(:final message):
        final builder = errorBuilder;
        if (builder != null) return builder(context, message);
        return Center(
            child: Text(message ?? '出错了', textAlign: TextAlign.center));
      case UiStateEmpty():
        return Center(child: empty ?? const Text('暂无数据'));
      case UiStateContent():
        return content;
    }
  }
}
