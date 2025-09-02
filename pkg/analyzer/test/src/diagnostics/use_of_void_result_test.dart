// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfVoidResultTest);
  });
}

@reflectiveTest
class UseOfVoidResultTest extends PubPackageResolutionTest {
  test_andVoidLhsError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x && true;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 19, 1)],
    );
  }

  test_andVoidRhsError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  true && x;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 27, 1)],
    );
  }

  test_assignment_toDynamic() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  // ignore:unused_local_variable
  dynamic v = x;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 65, 1)],
    );
  }

  test_assignment_toVoid() async {
    await assertNoErrorsInCode('''
void f(void x) {
  // ignore:unused_local_variable
  void v = x;
}
''');
  }

  test_assignmentExpression_function() async {
    await assertErrorsInCode(
      '''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''',
      [
        error(WarningCode.unusedLocalVariable, 38, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 49, 1),
      ],
    );
  }

  test_assignmentExpression_method() async {
    await assertErrorsInCode(
      '''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''',
      [
        error(WarningCode.unusedLocalVariable, 40, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 51, 1),
      ],
    );
  }

  test_assignmentToVoidParameterOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  g(x);
}
void g(void x) {}
''');
  }

  test_await() async {
    await assertErrorsInCode(
      '''
void f(void x) async {
  await x;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 31, 1)],
    );
  }

  test_constructorFieldInitializer_toDynamic() async {
    await assertErrorsInCode(
      '''
class A {
  dynamic f;
  A(void x) : f = x;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 41, 1)],
    );
  }

  test_constructorFieldInitializer_toVoid() async {
    await assertNoErrorsInCode('''
class A {
  void f;
  A(void x) : f = x;
}
''');
  }

  test_extensionApplication() async {
    await assertErrorsInCode(
      '''
extension E on String {
  int get g => 0;
}

void f() {}

void h() {
  E(f()).g;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 73, 3)],
    );
  }

  test_implicitReturnValue() async {
    await assertErrorsInCode(
      r'''
f() {}
class A {
  n() {
    var a = f();
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 33, 1)],
    );
  }

  test_inForLoop_error() async {
    await assertErrorsInCode(
      '''
class A {
  void m() {}
  n() {
    for(Object a = m();;) {}
  }
}''',
      [
        error(WarningCode.unusedLocalVariable, 47, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 51, 1),
      ],
    );
  }

  test_inForLoop_ok() async {
    await assertErrorsInCode(
      '''
class A {
  void m() {}
  n() {
    for(void a = m();;) {}
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 45, 1)],
    );
  }

  test_interpolateVoidValueError() async {
    await assertErrorsInCode(
      r'''
void f(void x) {
  "$x";
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 21, 1)],
    );
  }

  test_negateVoidValueError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  !x;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 20, 1)],
    );
  }

  test_nonVoidReturnValue() async {
    await assertErrorsInCode(
      r'''
int f() => 1;
g() {
  var a = f();
}
''',
      [error(WarningCode.unusedLocalVariable, 26, 1)],
    );
  }

  test_nullCheck() async {
    await assertErrorsInCode(
      r'''
f(void x) {
  x!;
}
''',
      [ExpectedError(CompileTimeErrorCode.useOfVoidResult, 14, 2)],
    );

    assertType(findNode.postfix('x!'), 'void');
  }

  test_orVoidLhsError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x || true;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 19, 1)],
    );
  }

  test_orVoidRhsError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  false || x;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 28, 1)],
    );
  }

  test_recordLiteral_namedField() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  (one: x,);
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 20, 6)],
    );
  }

  test_recordLiteral_positionalField() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  (x,);
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 20, 1)],
    );
  }

  test_switchStatement_expression() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  switch(x) {}
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 26, 1)],
    );
  }

  test_throwVoidValueError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  throw x;
}
''',
      [
        error(CompileTimeErrorCode.useOfVoidResult, 25, 1),
        error(CompileTimeErrorCode.throwOfInvalidType, 25, 1),
      ],
    );
  }

  test_unaryNegativeVoidFunction() async {
    await assertErrorsInCode(
      '''
void test(void f()) {
  -f();
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          24,
          1,
        ),
        error(CompileTimeErrorCode.useOfVoidResult, 25, 3),
      ],
    );
  }

  test_unaryNegativeVoidValueError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  -x;
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          19,
          1,
        ),
        error(CompileTimeErrorCode.useOfVoidResult, 20, 1),
      ],
    );
  }

  test_useOfVoidAsIndexAssignError() async {
    await assertErrorsInCode(
      '''
void f(List list, void x) {
  list[x] = null;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 35, 1)],
    );
  }

  test_useOfVoidAsIndexError() async {
    await assertErrorsInCode(
      '''
void f(List list, void x) {
  list[x];
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 35, 1)],
    );
  }

  test_useOfVoidAssignedToDynamicError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  dynamic z = x;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 27, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 31, 1),
      ],
    );
  }

  test_useOfVoidByIndexingError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x[0];
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 20, 3)],
    );
  }

  test_useOfVoidCallSetterError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x.foo = null;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 21, 3)],
    );
  }

  test_useOfVoidCastsOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  use(x as int);
}

void use(Object? x) {}
''');
  }

  test_useOfVoidInConditionalConditionError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x ? null : null;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 19, 1)],
    );
  }

  test_useOfVoidInConditionalLhsError() async {
    // A conditional expression is one of the allowed positions for `void`.
    await assertNoErrorsInCode('''
void f(bool c, void x) {
  c ? x : null;
}
''');
  }

  test_useOfVoidInConditionalRhsError() async {
    // A conditional expression is one of the allowed positions for `void`.
    await assertNoErrorsInCode('''
void f(bool c, void x) {
  c ? null : x;
}
''');
  }

  test_useOfVoidInDoWhileConditionError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  do {} while (x);
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 32, 1)],
    );
  }

  test_useOfVoidInExpStmtOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  x;
}
''');
  }

  test_useOfVoidInForeachIterableError() async {
    await assertErrorsInCode(
      r'''
void f(void x, var y) {
  for (y in x) {}
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedUseOfNullableValueAsIterator,
          36,
          1,
        ),
        error(CompileTimeErrorCode.useOfVoidResult, 36, 1),
      ],
    );
  }

  test_useOfVoidInForeachIterableError_declaredVariable() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  for (var v in x) {}
}
''',
      [
        error(WarningCode.unusedLocalVariable, 28, 1),
        error(
          CompileTimeErrorCode.uncheckedUseOfNullableValueAsIterator,
          33,
          1,
        ),
        error(CompileTimeErrorCode.useOfVoidResult, 33, 1),
      ],
    );
  }

  @failingTest // This test may be completely invalid.
  test_useOfVoidInForeachVariableError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  for (x in [1, 2]) {}
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 24, 1)],
    );
  }

  test_useOfVoidInForPartsOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  for (x; true; x) {}
}
''');
  }

  test_useOfVoidInIsTestError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x is int;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 19, 1)],
    );
  }

  test_useOfVoidInListLiteralError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  <dynamic>[x];
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 29, 1)],
    );
  }

  test_useOfVoidInListLiteralOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  [x];
}
''');
  }

  test_useOfVoidInMapLiteralKeyError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  <dynamic, int>{x : 4};
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 34, 1)],
    );
  }

  test_useOfVoidInMapLiteralKeyOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  ({x : 4});
}
''');
  }

  test_useOfVoidInMapLiteralValueError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  <int, dynamic>{4: x};
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 37, 1)],
    );
  }

  test_useOfVoidInMapLiteralValueOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  ({4: x});
}
''');
  }

  test_useOfVoidInNullOperatorLhsError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x ?? 1;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 19, 1)],
    );
  }

  test_useOfVoidInNullOperatorRhsOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  null ?? x;
}
''');
  }

  test_useOfVoidInSpecialAssignmentError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x += 1;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 21, 2)],
    );
  }

  test_useOfVoidInWhileConditionError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  while (x) {};
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 26, 1)],
    );
  }

  test_useOfVoidNullPropertyAccessError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x?.foo;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 22, 3)],
    );
  }

  test_useOfVoidPropertyAccessError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  x.foo;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 21, 3)],
    );
  }

  test_useOfVoidReturnInExtensionMethod() async {
    await assertErrorsInCode(
      '''
extension on void {
  testVoid() {
    // No access on void. Static type of `this` is void!
    this.toString();
  }
}
''',
      [
        error(WarningCode.unusedElement, 22, 8),
        error(CompileTimeErrorCode.useOfVoidResult, 96, 4),
      ],
    );
  }

  @failingTest
  test_useOfVoidReturnInNonVoidFunctionError() async {
    // TODO(mfairhurst): Get this test to pass once codebase is compliant.
    await assertErrorsInCode(
      '''
dynamic f(void x) {
  return x;
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 36, 1)],
    );
  }

  test_useOfVoidReturnInVoidFunctionOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  return x;
}
''');
  }

  test_useOfVoidWhenArgumentError() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  g(x);
}
void g(dynamic x) { }
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 21, 1)],
    );
  }

  test_useOfVoidWithInitializerOk() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  void y = x;
}
''',
      [error(WarningCode.unusedLocalVariable, 24, 1)],
    );
  }

  test_variableDeclaration_function_error() async {
    await assertErrorsInCode(
      '''
void f() {}
class A {
  n() {
    Object a = f();
  }
}''',
      [
        error(WarningCode.unusedLocalVariable, 41, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 45, 1),
      ],
    );
  }

  test_variableDeclaration_function_ok() async {
    await assertErrorsInCode(
      '''
void f() {}
class A {
  n() {
    void a = f();
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 39, 1)],
    );
  }

  test_variableDeclaration_method2() async {
    await assertErrorsInCode(
      '''
class A {
  void m() {}
  n() {
    Object a = m(), b = m();
  }
}''',
      [
        error(WarningCode.unusedLocalVariable, 43, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 47, 1),
        error(WarningCode.unusedLocalVariable, 52, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 56, 1),
      ],
    );
  }

  test_variableDeclaration_method_error() async {
    await assertErrorsInCode(
      '''
class A {
  void m() {}
  n() {
    Object a = m();
  }
}''',
      [
        error(WarningCode.unusedLocalVariable, 43, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 47, 1),
      ],
    );
  }

  test_variableDeclaration_method_ok() async {
    await assertErrorsInCode(
      '''
class A {
  void m() {}
  n() {
    void a = m();
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 41, 1)],
    );
  }

  test_yieldStarVoid_asyncStar() async {
    await assertErrorsInCode(
      '''
Object? f(void x) async* {
  yield* x;
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedUseOfNullableValueInYieldEach,
          36,
          1,
        ),
        error(CompileTimeErrorCode.yieldEachOfInvalidType, 36, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 36, 1),
      ],
    );
  }

  test_yieldStarVoid_syncStar() async {
    await assertErrorsInCode(
      '''
Object? f(void x) sync* {
  yield* x;
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedUseOfNullableValueInYieldEach,
          35,
          1,
        ),
        error(CompileTimeErrorCode.yieldEachOfInvalidType, 35, 1),
        error(CompileTimeErrorCode.useOfVoidResult, 35, 1),
      ],
    );
  }

  test_yieldVoid_asyncStar() async {
    await assertErrorsInCode(
      '''
dynamic f(void x) async* {
  yield x;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 35, 1)],
    );
  }

  test_yieldVoid_syncStar() async {
    await assertErrorsInCode(
      '''
dynamic f(void x) sync* {
  yield x;
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 34, 1)],
    );
  }
}
