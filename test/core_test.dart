import 'package:dart_jet/dart_jet.dart';
import 'package:flutter_test/flutter_test.dart';

class _Foo {}
class _FooA implements _Foo {}
class _FooB implements _Foo {}

class _Record {}

void main() {
  group('SpiRegistry', () {
    test('注册/查询/覆盖', () {
      final registry = SpiRegistry();
      registry.register<_Foo>(_Foo, _FooA());
      expect(registry.get<_Foo>(_Foo), isA<_FooA>());
      expect(registry.has(_Foo), isTrue);
      expect(() => registry.register<_Foo>(_Foo, _FooB()), throwsStateError);
      registry.register<_Foo>(_Foo, _FooB(), override: true);
      expect(registry.get<_Foo>(_Foo), isA<_FooB>());
      registry.unregister(_Foo);
      expect(registry.has(_Foo), isFalse);
    });
  });

  group('UiState', () {
    test('初始四态类型可以分支', () {
      UiState state = const UiStateLoading();
      expect(state, isA<UiStateLoading>());
      state = const UiStateError('boom');
      expect((state as UiStateError).message, 'boom');
      state = const UiStateEmpty();
      expect(state, isA<UiStateEmpty>());
      state = const UiStateContent();
      expect(state, isA<UiStateContent>());
    });
  });

  group('XJet init', () {
    test('默认注册与显式 override', () {
      XJet.init(XJetConfig(debug: false));
      expect(XJet.isInitialized, isTrue);
      expect(XJet.cache(), isA<InMemoryCacheProvider>());
      expect(XJet.database(), isA<InMemoryDatabaseProvider>());
      expect(XJet.permission(), isA<GrantedPermissionService>());
      expect(XJet.errorInterceptor(), isA<LogExceptionInterceptor>());

      final custom = _TrackingCache();
      XJet.override<CacheProvider>(CacheProvider, custom);
      expect(XJet.cache(), same(custom));
      XJet.cache().put('k', 'v');
      expect(custom.putCalls, 1);
    });

    test('默认内存数据库可注册 DAO 并读写表', () async {
      final db = InMemoryDatabaseProvider();
      final record = _Record();
      db.registerDao<_Record>(_Record, record);
      expect(db.dao<_Record>(_Record), same(record));

      db.records('news').add({'id': 1, 'title': 'a'});
      expect(db.records('news'), hasLength(1));

      await db.clearAllTables();
      expect(db.records('news'), isEmpty);
    });

    test('默认权限服务已全部授予', () async {
      final service = XJet.permission();
      expect(await service.areGranted([XPermission.camera, XPermission.photos]),
          isTrue);
      expect((await service.missing([XPermission.microphone])), isEmpty);
    });
  });

  group('SpiConfig', () {
    test('可用 JSON 加载 SPI 工厂', () {
      final registry = SpiRegistry();
      final config = SpiConfig()
        ..registerApi('_Foo', _Foo)
        ..registerFactory('_FooA', InstanceProvider<_Foo>(_FooA()));

      final registered = config.loadJson(registry, '{"_Foo":"_FooA"}');
      expect(registered, [_Foo]);
      expect(registry.get<_Foo>(_Foo), isA<_FooA>());
    });
  });
}

class _TrackingCache extends InMemoryCacheProvider {
  int putCalls = 0;
  @override
  void put(String key, String value) {
    putCalls++;
    super.put(key, value);
  }
}
