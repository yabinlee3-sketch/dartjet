/// 错误级别，对应 Android ErrorSeverity。
enum ErrorSeverity { info, warning, error }

/// 全局异常拦截契约，对应 Android ExceptionInterceptor。
abstract class ExceptionInterceptor {
  void onError(
    String source,
    Object error, {
    ErrorSeverity severity = ErrorSeverity.error,
  });
}

/// 默认实现：输出到控制台日志，可被 override 替换。
class LogExceptionInterceptor implements ExceptionInterceptor {
  @override
  void onError(
    String source,
    Object error, {
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final prefix = switch (severity) {
      ErrorSeverity.info => 'INFO',
      ErrorSeverity.warning => 'WARNING',
      ErrorSeverity.error => 'ERROR',
    };
    // ignore: avoid_print
    print('[$prefix] $source: $error');
  }
}
