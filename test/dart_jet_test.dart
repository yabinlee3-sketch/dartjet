import 'package:dart_jet/dart_jet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DartJet 包可导入且 UiState 可构造', () {
    const state = UiStateContent();
    expect(state, isA<UiStateContent>());
  });
}
