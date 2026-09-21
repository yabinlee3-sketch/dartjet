import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'net.dart';
import 'providers.dart';

/// 内存缓存默认实现。
class InMemoryCacheProvider implements CacheProvider {
  final Map<String, Object> _store = {};

  @override
  String? get(String key) => _store[key] as String?;

  @override
  void put(String key, String value) => _store[key] = value;

  @override
  Uint8List? getBytes(String key) => _store[key] as Uint8List?;

  @override
  void putBytes(String key, Uint8List value) => _store[key] = value;

  @override
  void remove(String key) => _store.remove(key);

  @override
  void clear() => _store.clear();
}

/// 事件总线默认实现：once-off 广播 + sticky 保留最近值。
class XJetEventBus implements EventBusProvider {
  final StreamController<Object> _events =
      StreamController<Object>.broadcast();
  final Map<Type, Object> _sticky = {};

  @override
  Stream<T> events<T>() => _events.stream.where((e) => e is T).cast<T>();

  @override
  Stream<T> stickyEvents<T>() =>
      _events.stream.where((e) => e is T).cast<T>();

  @override
  Future<void> post(Object event) async {
    _events.add(event);
  }

  @override
  Future<void> postSticky(Object event) async {
    _sticky[event.runtimeType] = event;
    _events.add(event);
  }
}

/// 基于 package:http 的默认网络实现。
/// 业务层永远不直接 import http，只通过 HttpProvider / XJet.http。
class DartHttpProvider implements HttpProvider {
  final http.Client? _client;
  DartHttpProvider([this._client]);

  @override
  Future<HttpResponse> execute(HttpRequest request) async {
    final client = _client ?? http.Client();
    try {
      final uri = Uri.parse(request.url);
      final req = http.Request(request.method, uri)
        ..headers.addAll(request.headers);
      if (request.body != null) {
        req.bodyBytes = request.body!;
      }
      final streamed = await client
          .send(req)
          .timeout(const Duration(seconds: 15));
      final resp = await http.Response.fromStream(streamed);
      final headers = <String, List<String>>{};
      resp.headers.forEach((k, v) {
        headers[k] = [v];
      });
      return HttpResponse(
        status: resp.statusCode,
        headers: headers,
        body: resp.bodyBytes,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

