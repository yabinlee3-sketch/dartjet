/// 懒工厂契约，对应 Android `ServiceProvider`。
/// Dart 没有无参反射构造，因此用闭包工厂承担"新建实例"职责。
abstract class ServiceProvider<T> {
  T create();
}

/// 固定实例。
class InstanceProvider<T> implements ServiceProvider<T> {
  final T _instance;
  InstanceProvider(this._instance);

  @override
  T create() => _instance;
}

/// 每次 create 新建一个实例。
class NewInstanceProvider<T> implements ServiceProvider<T> {
  final T Function() _factory;
  NewInstanceProvider(this._factory);

  @override
  T create() => _factory();
}
