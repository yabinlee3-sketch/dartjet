import 'package:dart_jet/dart_jet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubViewModel extends XViewModel {
  void goContent() {
    setContent();
  }
}

class _StubPage extends XPage<_StubViewModel> {
  const _StubPage();

  @override
  _StubViewModel createViewModel(BuildContext context) => _StubViewModel();

  @override
  State<XPage<_StubViewModel>> createState() => _StubPageState();
}

class _StubPageState extends XPageState<_StubViewModel> {
  @override
  Widget build(BuildContext context) {
    return XJetStateBox(
      state: viewModel.uiState.value,
      content: const Text('CONTENT_READY'),
    );
  }
}

void main() {
  test('ListDataSource 数据操作', () {
    final source = ListDataSource<int>([1, 2]);
    expect(source.value, [1, 2]);
    source.addData([3]);
    expect(source.value, [1, 2, 3]);
    source.setData([9]);
    expect(source.value, [9]);
    source.clear();
    expect(source.value, isEmpty);
  });

  testWidgets('XJetStateBox 四态渲染', (tester) async {
    Widget wrap(UiState state) => MaterialApp(
          home: Scaffold(
            body: XJetStateBox(
              state: state,
              content: const Text('CONTENT_READY'),
            ),
          ),
        );

    await tester.pumpWidget(wrap(const UiStateLoading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(wrap(const UiStateError('oops')));
    expect(find.text('oops'), findsOneWidget);

    await tester.pumpWidget(wrap(const UiStateEmpty()));
    expect(find.text('暂无数据'), findsOneWidget);

    await tester.pumpWidget(wrap(const UiStateContent()));
    expect(find.text('CONTENT_READY'), findsOneWidget);
  });

  testWidgets('XListView 渲染与点击', (tester) async {
    final source = ListDataSource<String>(['a', 'b']);
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: XListView<String>(
            source: source,
            itemBuilder: (context, item, index) =>
                ListTile(title: Text(item), onTap: () => taps.add(item)),
          ),
        ),
      ),
    );
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    await tester.tap(find.text('a'));
    expect(taps, ['a']);
  });

  testWidgets('XPage 生命周期绑定 ViewModel', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _StubPage()));
    final state = tester.state<_StubPageState>(find.byType(_StubPage));
    state.viewModel.goContent();
    await tester.pumpAndSettle();
    expect(find.text('CONTENT_READY'), findsOneWidget);
  });
}
