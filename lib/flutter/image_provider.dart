import 'package:flutter/painting.dart';
import '../core/providers.dart';

/// 默认图片加载：把 URL 映射为 NetworkImage 并回调。
class DartImageLoaderProvider implements ImageLoaderProvider {
  @override
  void load(String url, ImageLoadTarget target) {
    try {
      target.onLoadSuccess(NetworkImage(url));
    } catch (e, st) {
      target.onLoadFailed(st.toString().isEmpty ? e : e);
    }
  }
}

