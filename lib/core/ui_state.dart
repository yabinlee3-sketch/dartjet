/// 页面四态，对应 Android XJet 的 [UiState]。
/// Dart 不支持 sealed 下嵌套对象字面量，因此拆成四个独立类。
sealed class UiState {
  const UiState();
}

/// 加载中：初始态与重试后的默认态。
final class UiStateLoading extends UiState {
  const UiStateLoading();
}

/// 出错：携带可选提示信息。
final class UiStateError extends UiState {
  final String? message;
  const UiStateError([this.message]);
}

/// 空态：无数据但仍可展示空页。
final class UiStateEmpty extends UiState {
  const UiStateEmpty();
}

/// 内容就绪：页面渲染真正的业务内容。
final class UiStateContent extends UiState {
  const UiStateContent();
}
