// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseExpressionTypeImplementsEqualsTest);
    defineReflectiveTests(CaseExpressionTypeImplementsEqualsTest_Language218);
    defineReflectiveTests(
      CaseExpressionTypeImplementsEqualsWithoutNullSafetyTest,
    );
  });
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsTest extends PubPackageResolutionTest
    with CaseExpressionTypeImplementsEqualsTestCases {
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/50502')
  @override
  test_implements() {
    return super.test_implements();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/50502')
  @override
  test_Object() {
    return super.test_Object();
  }
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsTest_Language218
    extends PubPackageResolutionTest
    with WithLanguage218Mixin, CaseExpressionTypeImplementsEqualsTestCases {}

mixin CaseExpressionTypeImplementsEqualsTestCases on PubPackageResolutionTest {
  test_declares() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  final int value;

  const A(this.value);

  bool operator==(Object other);
}

class B extends A {
  const B(int value) : super(value);
}

void f(e) {
  switch (e) {
    case const B(0):
      break;
    case const B(1):
      break;
  }
}
''');
  }

  test_implements() async {
    await assertErrorsInCode(r'''
class A {
  final int value;

  const A(this.value);

  bool operator ==(Object other) {
    return false;
  }
}

void f(e) {
  switch (e) {
    case A(0):
      break;
  }
}
''', [
      error(
          CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, 150, 4),
    ]);
  }

  test_int() async {
    await assertNoErrorsInCode(r'''
void f(e) {
  switch (e) {
    case 0:
      break;
  }
}
''');
  }

  test_Object() async {
    await assertNoErrorsInCode(r'''
class A {
  final int value;
  const A(this.value);
}

void f(e) {
  switch (e) {
    case A(0):
      break;
  }
}
''');
  }

  test_String() async {
    await assertNoErrorsInCode(r'''
void f(e) {
  switch (e) {
    case '0':
      break;
  }
}
''');
  }
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, CaseExpressionTypeImplementsEqualsTestCases {
  @override
  test_implements() async {
    await assertErrorsInCode(r'''
class A {
  final int value;

  const A(this.value);

  bool operator ==(Object other) {
    return false;
  }
}

void f(e) {
  switch (e) {
    case A(0):
      break;
  }
}
''', [
      error(
          CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, 128, 6),
    ]);
  }
}
