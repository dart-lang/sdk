// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfNeverTest);
    defineReflectiveTests(InvalidUseOfNeverTest_Legacy);
  });
}

@reflectiveTest
class InvalidUseOfNeverTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  @failingTest
  test_binaryExpression_never_eqEq() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main(Never x) {
  x == 0;
}
''');
  }

  @failingTest
  test_binaryExpression_never_plus() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main(Never x) {
  x + 0;
}
''');
  }

  @failingTest
  test_binaryExpression_neverQ_eqEq() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main(Never? x) {
  x == 0;
}
''');
  }

  @failingTest
  test_binaryExpression_neverQ_plus() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main(Never? x) {
  x + 0;
}
''');
  }

  test_conditionalExpression_falseBranch() async {
    await assertNoErrorsInCode(r'''
void main(bool c, Never x) {
  c ? 0 : x;
}
''');
  }

  test_conditionalExpression_trueBranch() async {
    await assertNoErrorsInCode(r'''
void main(bool c, Never x) {
  c ? x : 0;
}
''');
  }

  test_functionExpressionInvocation_never() async {
    await assertErrorsInCode(r'''
void main(Never x) {
  x();
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 23, 1),
    ]);
  }

  test_functionExpressionInvocation_neverQ() async {
    await assertErrorsInCode(r'''
void main(Never? x) {
  x();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 24, 1),
    ]);
  }

  test_invocationArgument() async {
    await assertNoErrorsInCode(r'''
void main(f, Never x) {
  f(x);
}
''');
  }

  test_methodInvocation_never() async {
    await assertErrorsInCode(r'''
void main(Never x) {
  x.foo(1 + 2);
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 23, 1),
    ]);

    assertMethodInvocation(
      findNode.methodInvocation('.foo(1 + 2)'),
      null,
      'dynamic',
      expectedType: 'Never',
    );

    // Verify that arguments are resolved.
    assertType(findNode.binary('1 + 2'), 'int');
  }

  test_methodInvocation_never_toString() async {
    await assertErrorsInCode(r'''
void main(Never x) {
  x.toString(1 + 2);
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 23, 1),
    ]);

    assertMethodInvocation(
      findNode.methodInvocation('.toString(1 + 2)'),
      null,
      'dynamic',
      expectedType: 'Never',
    );

    // Verify that arguments are resolved.
    assertType(findNode.binary('1 + 2'), 'int');
  }

  test_methodInvocation_neverQ_toString() async {
    await assertErrorsInCode(r'''
void main(Never? x) {
  x.toString(1 + 2);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 34, 7),
    ]);

    assertMethodInvocation(
      findNode.methodInvocation('.toString(1 + 2)'),
      typeProvider.objectType.element.getMethod('toString'),
      'String Function()',
      expectedType: 'String',
    );

    // Verify that arguments are resolved.
    assertType(findNode.binary('1 + 2'), 'int');
  }

  @failingTest
  test_postfixExpression_never_plusPlus() async {
    // Reports 'undefined operator'
    await assertErrorsInCode(r'''
void main(Never x) {
  x++;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  @failingTest
  test_postfixExpression_neverQ_plusPlus() async {
    // Reports 'undefined operator'
    await assertErrorsInCode(r'''
void main(Never x) {
  x++;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  @failingTest
  test_prefixExpression_never_plusPlus() async {
    // Reports 'undefined operator'
    await assertErrorsInCode(r'''
void main(Never x) {
  ++x;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  @failingTest
  test_prefixExpression_neverQ_plusPlus() async {
    // Reports 'undefined operator'
    await assertErrorsInCode(r'''
void main(Never x) {
  ++x;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  @FailingTest(reason: 'Types are wrong')
  test_propertyAccess_never() async {
    await assertErrorsInCode(r'''
void main(Never x) {
  x.foo;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 23, 1),
    ]);

    assertElementNull(findNode.simple('foo;'));
    assertType(findNode.prefixed('x.foo'), 'Never');
  }

  @failingTest
  test_propertyAccess_never_hashCode() async {
    // reports undefined getter
    await assertNoErrorsInCode(r'''
void main(Never x) {
  x.hashCode;
}
''');
  }

  @failingTest
  test_propertyAccess_never_tearOff_toString() async {
    // reports undefined getter
    await assertNoErrorsInCode(r'''
void main(Never x) {
  x.toString;
}
''');
  }

  @FailingTest(reason: 'Types are wrong')
  test_propertyAccess_neverQ() async {
    await assertErrorsInCode(r'''
void main(Never x) {
  x.foo;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 23, 1),
    ]);

    assertElementNull(findNode.simple('foo;'));
    assertType(findNode.prefixed('x.foo'), 'Never');
  }

  @failingTest
  test_propertyAccess_neverQ_hashCode() async {
    // reports undefined getter
    await assertNoErrorsInCode(r'''
void main(Never? x) {
  x.hashCode;
}
''');
  }
}

/// Construct Never* by using throw expressions and assert no errors.
@reflectiveTest
class InvalidUseOfNeverTest_Legacy extends DriverResolutionTest {
  @failingTest
  test_binaryExpression_eqEq() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main() {
  (throw '') == 0;
}
''');
  }

  @failingTest
  test_binaryExpression_plus() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main() {
  (throw '') + 0;
}
''');
  }

  test_methodInvocation_toString() async {
    await assertNoErrorsInCode(r'''
void main() {
  (throw '').toString();
}
''');
  }

  @failingTest
  test_propertyAccess_toString() async {
    // Reports undefined getter (it seems to get confused by the tear-off).
    await assertNoErrorsInCode(r'''
void main() {
  (throw '').toString;
}
''');
  }

  @failingTest
  test_throw_getter_hashCode() async {
    // Reports undefined getter.
    await assertNoErrorsInCode(r'''
void main() {
  (throw '').hashCode;
}
''');
  }
}
