// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HorizontalInferenceEnabledTest);
    defineReflectiveTests(HorizontalInferenceDisabledTest);
  });
}

@reflectiveTest
class HorizontalInferenceDisabledTest extends PubPackageResolutionTest
    with HorizontalInferenceTestCases {
  @override
  String get testPackageLanguageVersion => '2.17';
}

@reflectiveTest
class HorizontalInferenceEnabledTest extends PubPackageResolutionTest
    with HorizontalInferenceTestCases {
  @override
  List<String> get experiments =>
      [...super.experiments, EnableString.inference_update_1];
}

mixin HorizontalInferenceTestCases on PubPackageResolutionTest {
  bool get _isEnabled => experiments.contains(EnableString.inference_update_1);

  test_closure_passed_to_identical() async {
    await assertNoErrorsInCode('''
test() => identical(() {}, () {});
''');
    // No further assertions; we just want to make sure the interaction between
    // flow analysis for `identical` and deferred analysis of closures doesn't
    // lead to a crash.
  }

  test_fold_inference() async {
    var code = '''
example(List<int> list) {
  var a = list.fold(0, (x, y) => x + y);
}
''';
    if (_isEnabled) {
      await assertErrorsInCode(code, [
        error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
      ]);
      assertType(findElement.localVar('a').type, 'int');
      assertType(findElement.parameter('x').type, 'int');
      assertType(findElement.parameter('y').type, 'int');
      expect(
          findNode.binary('x + y').staticElement!.enclosingElement.name, 'num');
    } else {
      await assertErrorsInCode(code, [
        error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
        error(
            CompileTimeErrorCode
                .UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE,
            61,
            1),
      ]);
    }
  }

  test_horizontal_inference_propagate_to_return_type() async {
    await assertErrorsInCode('''
U f<T, U>(T t, U Function(T) g) => throw '';
test() {
  var a = f(0, (x) => [x]);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 60, 1),
    ]);
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![0], 'int');
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![1],
        _isEnabled ? 'List<int>' : 'List<Object?>');
    assertType(
        findNode.methodInvocation('f(').staticInvokeType,
        _isEnabled
            ? 'List<int> Function(int, List<int> Function(int))'
            : 'List<Object?> Function(int, List<Object?> Function(int))');
    assertType(findNode.simpleParameter('x)').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
    assertType(findNode.variableDeclaration('a =').declaredElement!.type,
        _isEnabled ? 'List<int>' : 'List<Object?>');
  }

  test_horizontal_inference_simple() async {
    await assertNoErrorsInCode('''
void f<T>(T t, void Function(T) g) {}
test() => f(0, (x) {});
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function(int, void Function(int))');
    assertType(findNode.simpleParameter('x').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
  }

  test_horizontal_inference_simple_named() async {
    await assertNoErrorsInCode('''
void f<T>({required T t, required void Function(T) g}) {}
test() => f(t: 0, g: (x) {});
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function({required void Function(int) g, required int t})');
    assertType(findNode.simpleParameter('x').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
  }

  test_write_capture_deferred() async {
    await assertNoErrorsInCode('''
test(int? i) {
  if (i != null) {
    f(() { i = null; }, i); // (1)
    i; // (2)
  }
}
void f(void Function() g, Object? x) {}
''');
    // With the feature enabled, analysis of the closure is deferred until after
    // all the other arguments to `f`, so the `i` at (1) is not yet write
    // captured and retains its promoted value.  With the experiment disabled,
    // it is write captured immediately.
    assertType(findNode.simple('i); // (1)'), _isEnabled ? 'int' : 'int?');
    // At (2), after the call to `f`, the write capture has taken place
    // regardless of whether the experiment is enabled.
    assertType(findNode.simple('i; // (2)'), 'int?');
  }

  test_write_capture_deferred_named() async {
    await assertNoErrorsInCode('''
test(int? i) {
  if (i != null) {
    f(g: () { i = null; }, x: i); // (1)
    i; // (2)
  }
}
void f({required void Function() g, Object? x}) {}
''');
    // With the feature enabled, analysis of the closure is deferred until after
    // all the other arguments to `f`, so the `i` at (1) is not yet write
    // captured and retains its promoted value.  With the experiment disabled,
    // it is write captured immediately.
    assertType(findNode.simple('i); // (1)'), _isEnabled ? 'int' : 'int?');
    // At (2), after the call to `f`, the write capture has taken place
    // regardless of whether the experiment is enabled.
    assertType(findNode.simple('i; // (2)'), 'int?');
  }
}
