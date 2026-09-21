/// 权限枚举。
enum XPermission {
  camera,
  microphone,
  location,
  notifications,
  storage,
  photos,
  calendar,
}

/// 权限服务契约。
/// 默认实现为"全部已授予"，可用于测试与不支持权限能力的平台；
/// 需要真实权限时请用平台实现 override 替换。
abstract class PermissionService {
  Future<bool> areGranted(List<XPermission> permissions);
  Future<List<XPermission>> missing(List<XPermission> permissions);
  Future<bool> request(List<XPermission> permissions);
  Future<bool> shouldShowRationale(XPermission permission);
}

/// 默认权限实现：不做任何平台校验，返回已全部授予。
class GrantedPermissionService implements PermissionService {
  @override
  Future<bool> areGranted(List<XPermission> permissions) async => true;

  @override
  Future<List<XPermission>> missing(List<XPermission> permissions) async => [];

  @override
  Future<bool> request(List<XPermission> permissions) async => true;

  @override
  Future<bool> shouldShowRationale(XPermission permission) async => false;
}
