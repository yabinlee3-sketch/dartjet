import 'package:flutter/material.dart';

/// 全局主题包装，对应 Android XJetTheme。
class XJetTheme extends StatelessWidget {
  final Widget child;
  final ThemeData? theme;

  const XJetTheme({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    return Theme(data: theme ?? ThemeData(), child: child);
  }
}
