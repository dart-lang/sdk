// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryExpressionResolutionTest);
    defineReflectiveTests(BinaryExpressionResolutionWithNnbdTest);
  });
}

@reflectiveTest
class BinaryExpressionResolutionTest extends DriverResolutionTest {
  test_bangEq() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a != b;
}
''');

    assertBinaryExpression(
      findNode.binary('a != b'),
      element: elementMatcher(
        numElement.getMethod('=='),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'bool',
    );
  }

  test_eqEq() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a == b;
}
''');

    assertBinaryExpression(
      findNode.binary('a == b'),
      element: elementMatcher(
        numElement.getMethod('=='),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'bool',
    );
  }

  test_eqEqEq() async {
    await assertErrorsInCode(r'''
f(int a, int b) {
  a === b;
}
''', [
      error(ScannerErrorCode.UNSUPPORTED_OPERATOR, 22, 1),
    ]);

    assertBinaryExpression(
      findNode.binary('a === b'),
      element: null,
      type: 'dynamic',
    );

    assertType(findNode.simple('a ==='), 'int');
    assertType(findNode.simple('b;'), 'int');
  }

  test_ifNull() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a ?? b;
}
''');

    assertBinaryExpression(
      findNode.binary('a ?? b'),
      element: null,
      type: 'num',
    );
  }

  test_logicalAnd() async {
    await assertNoErrorsInCode(r'''
f(bool a, bool b) {
  a && b;
}
''');

    assertBinaryExpression(
      findNode.binary('a && b'),
      element: boolElement.getMethod('&&'),
      type: 'bool',
    );
  }

  test_logicalOr() async {
    await assertNoErrorsInCode(r'''
f(bool a, bool b) {
  a || b;
}
''');

    assertBinaryExpression(
      findNode.binary('a || b'),
      element: boolElement.getMethod('||'),
      type: 'bool',
    );
  }

  test_plus_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_plus_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a + b;
}
''');

    assertBinaryExpression(
      findNode.binary('a + b'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_receiverTypeParameter_bound_dynamic() async {
    await assertNoErrorsInCode(r'''
f<T extends dynamic>(T a) {
  a + 0;
}
''');

    assertBinaryExpression(
      findNode.binary('a + 0'),
      element: null,
      type: 'dynamic',
    );
  }

  test_receiverTypeParameter_bound_num() async {
    await assertNoErrorsInCode(r'''
f<T extends num>(T a) {
  a + 0;
}
''');

    assertBinaryExpression(
      findNode.binary('a + 0'),
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'num',
    );
  }

  test_slash() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a / b;
}
''');

    assertBinaryExpression(
      findNode.binary('a / b'),
      element: elementMatcher(
        numElement.getMethod('/'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_star_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a * b;
}
''');

    assertBinaryExpression(
      findNode.binary('a * b'),
      element: elementMatcher(
        numElement.getMethod('*'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_star_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a * b;
}
''');

    assertBinaryExpression(
      findNode.binary('a * b'),
      element: elementMatcher(
        numElement.getMethod('*'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'int',
    );
  }
}

@reflectiveTest
class BinaryExpressionResolutionWithNnbdTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    )
    ..implicitCasts = false;

  @override
  bool get typeToStringWithNullability => true;

  test_ifNull_left_nullableContext() async {
    await assertNoErrorsInCode(r'''
T f<T>(T t) => t;

int g() => f(null) ?? 0;
''');

    assertMethodInvocation2(
      findNode.methodInvocation('f(null)'),
      element: findElement.topFunction('f'),
      typeArgumentTypes: ['int?'],
      invokeType: 'int? Function(int?)',
      type: 'int?',
    );

    assertBinaryExpression(
      findNode.binary('?? 0'),
      element: null,
      type: 'int',
    );
  }

  test_ifNull_nullableInt_int() async {
    await assertNoErrorsInCode(r'''
main(int? x, int y) {
  x ?? y;
}
''');

    assertBinaryExpression(
      findNode.binary('x ?? y'),
      element: null,
      type: 'int',
    );
  }

  test_ifNull_nullableInt_nullableDouble() async {
    await assertNoErrorsInCode(r'''
main(int? x, double? y) {
  x ?? y;
}
''');

    assertBinaryExpression(
      findNode.binary('x ?? y'),
      element: null,
      type: 'num?',
    );
  }

  test_ifNull_nullableInt_nullableInt() async {
    await assertNoErrorsInCode(r'''
main(int? x) {
  x ?? x;
}
''');

    assertBinaryExpression(
      findNode.binary('x ?? x'),
      element: null,
      type: 'int?',
    );
  }
}
