import 'package:dart_jet/dart_jet.dart';

import 'app/news_app.dart';

void main() {
  // 等价 XDroid demo 的 App.java：启动入口；装配逻辑集中在 app/news_app.dart。
  xJetRunApp(createNewsApp());
}
