import 'dart:typed_data';

/// 不可变 HTTP 请求，对应 Android HttpRequest。
class HttpRequest {
  final String method;
  final String url;
  final Map<String, String> headers;
  final Uint8List? body;
  final int connectTimeoutMillis;
  final int readTimeoutMillis;

  const HttpRequest({
    this.method = 'GET',
    required this.url,
    this.headers = const {},
    this.body,
    this.connectTimeoutMillis = 10000,
    this.readTimeoutMillis = 10000,
  });
}

/// HTTP 响应，对应 Android HttpResponse。
class HttpResponse {
  final int status;
  final Map<String, List<String>> headers;
  final Uint8List? body;

  HttpResponse({
    required this.status,
    this.headers = const {},
    this.body,
  });

  String get bodyText {
    final bytes = body;
    return bytes == null ? '' : String.fromCharCodes(bytes);
  }

  bool get isSuccess => status >= 200 && status < 300;
}

/// 网络 SPI 契约，对应 Android HttpProvider。
abstract class HttpProvider {
  Future<HttpResponse> execute(HttpRequest request);
}
