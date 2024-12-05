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
    await assertErrorsInCode('''
void f(void x) {
  x && true;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 19, 1),
    ]);
  }

  test_andVoidRhsError() async {
    await assertErrorsInCode('''
void f(void x) {
  true && x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 27, 1),
    ]);
  }

  test_assignment_toDynamic() async {
    await assertErrorsInCode('''
void f(void x) {
  // ignore:unused_local_variable
  dynamic v = x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 65, 1),
    ]);
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
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 38, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 49, 1),
    ]);
  }

  test_assignmentExpression_method() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
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
    await assertErrorsInCode('''
void f(void x) async {
  await x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 31, 1),
    ]);
  }

  test_constructorFieldInitializer_toDynamic() async {
    await assertErrorsInCode('''
class A {
  dynamic f;
  A(void x) : f = x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 41, 1),
    ]);
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
    await assertErrorsInCode('''
extension E on String {
  int get g => 0;
}

void f() {}

void h() {
  E(f()).g;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 73, 3),
    ]);
  }

  test_implicitReturnValue() async {
    await assertErrorsInCode(r'''
f() {}
class A {
  n() {
    var a = f();
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);
  }

  test_inForLoop_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    for(Object a = m();;) {}
  }
}''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_inForLoop_ok() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    for(void a = m();;) {}
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 45, 1),
    ]);
  }

  test_interpolateVoidValueError() async {
    await assertErrorsInCode(r'''
void f(void x) {
  "$x";
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 21, 1),
    ]);
  }

  test_negateVoidValueError() async {
    await assertErrorsInCode('''
void f(void x) {
  !x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 20, 1),
    ]);
  }

  test_nonVoidReturnValue() async {
    await assertErrorsInCode(r'''
int f() => 1;
g() {
  var a = f();
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
  }

  test_nullCheck() async {
    await assertErrorsInCode(r'''
f(void x) {
  x!;
}
''', [ExpectedError(CompileTimeErrorCode.USE_OF_VOID_RESULT, 14, 2)]);

    assertType(findNode.postfix('x!'), 'void');
  }

  test_orVoidLhsError() async {
    await assertErrorsInCode('''
void f(void x) {
  x || true;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 19, 1),
    ]);
  }

  test_orVoidRhsError() async {
    await assertErrorsInCode('''
void f(void x) {
  false || x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 28, 1),
    ]);
  }

  test_recordLiteral_namedField() async {
    await assertErrorsInCode('''
void f(void x) {
  (one: x,);
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 20, 6),
    ]);
  }

  test_recordLiteral_positionalField() async {
    await assertErrorsInCode('''
void f(void x) {
  (x,);
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 20, 1),
    ]);
  }

  test_switchStatement_expression() async {
    await assertErrorsInCode('''
void f(void x) {
  switch(x) {}
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_throwVoidValueError() async {
    await assertErrorsInCode('''
void f(void x) {
  throw x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 25, 1),
      error(CompileTimeErrorCode.THROW_OF_INVALID_TYPE, 25, 1),
    ]);
  }

  test_unaryNegativeVoidFunction() async {
    await assertErrorsInCode('''
void test(void f()) {
  -f();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          24, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 25, 3),
    ]);
  }

  test_unaryNegativeVoidValueError() async {
    await assertErrorsInCode('''
void f(void x) {
  -x;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          19, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 20, 1),
    ]);
  }

  test_useOfVoidAsIndexAssignError() async {
    await assertErrorsInCode('''
void f(List list, void x) {
  list[x] = null;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 35, 1),
    ]);
  }

  test_useOfVoidAsIndexError() async {
    await assertErrorsInCode('''
void f(List list, void x) {
  list[x];
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 35, 1),
    ]);
  }

  test_useOfVoidAssignedToDynamicError() async {
    await assertErrorsInCode('''
void f(void x) {
  dynamic z = x;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 27, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 31, 1),
    ]);
  }

  test_useOfVoidByIndexingError() async {
    await assertErrorsInCode('''
void f(void x) {
  x[0];
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 20, 3),
    ]);
  }

  test_useOfVoidCallSetterError() async {
    await assertErrorsInCode('''
void f(void x) {
  x.foo = null;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 21, 3),
    ]);
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
    await assertErrorsInCode('''
void f(void x) {
  x ? null : null;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 19, 1),
    ]);
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
    await assertErrorsInCode('''
void f(void x) {
  do {} while (x);
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 32, 1),
    ]);
  }

  test_useOfVoidInExpStmtOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  x;
}
''');
  }

  test_useOfVoidInForeachIterableError() async {
    await assertErrorsInCode(r'''
void f(void x, var y) {
  for (y in x) {}
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR,
          36, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 36, 1),
    ]);
  }

  test_useOfVoidInForeachIterableError_declaredVariable() async {
    await assertErrorsInCode('''
void f(void x) {
  for (var v in x) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 28, 1),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR,
          33, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 33, 1),
    ]);
  }

  @failingTest // This test may be completely invalid.
  test_useOfVoidInForeachVariableError() async {
    await assertErrorsInCode('''
void f(void x) {
  for (x in [1, 2]) {}
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 24, 1),
    ]);
  }

  test_useOfVoidInForPartsOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  for (x; true; x) {}
}
''');
  }

  test_useOfVoidInIsTestError() async {
    await assertErrorsInCode('''
void f(void x) {
  x is int;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 19, 1),
    ]);
  }

  test_useOfVoidInListLiteralError() async {
    await assertErrorsInCode('''
void f(void x) {
  <dynamic>[x];
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 29, 1),
    ]);
  }

  test_useOfVoidInListLiteralOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  [x];
}
''');
  }

  test_useOfVoidInMapLiteralKeyError() async {
    await assertErrorsInCode('''
void f(void x) {
  <dynamic, int>{x : 4};
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 34, 1),
    ]);
  }

  test_useOfVoidInMapLiteralKeyOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  ({x : 4});
}
''');
  }

  test_useOfVoidInMapLiteralValueError() async {
    await assertErrorsInCode('''
void f(void x) {
  <int, dynamic>{4: x};
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 37, 1),
    ]);
  }

  test_useOfVoidInMapLiteralValueOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  ({4: x});
}
''');
  }

  test_useOfVoidInNullOperatorLhsError() async {
    await assertErrorsInCode('''
void f(void x) {
  x ?? 1;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 19, 1),
    ]);
  }

  test_useOfVoidInNullOperatorRhsOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  null ?? x;
}
''');
  }

  test_useOfVoidInSpecialAssignmentError() async {
    await assertErrorsInCode('''
void f(void x) {
  x += 1;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 21, 2),
    ]);
  }

  test_useOfVoidInWhileConditionError() async {
    await assertErrorsInCode('''
void f(void x) {
  while (x) {};
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_useOfVoidNullPropertyAccessError() async {
    await assertErrorsInCode('''
void f(void x) {
  x?.foo;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 22, 3),
    ]);
  }

  test_useOfVoidPropertyAccessError() async {
    await assertErrorsInCode('''
void f(void x) {
  x.foo;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 21, 3),
    ]);
  }

  test_useOfVoidReturnInExtensionMethod() async {
    await assertErrorsInCode('''
extension on void {
  testVoid() {
    // No access on void. Static type of `this` is void!
    this.toString();
  }
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 22, 8),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 96, 4),
    ]);
  }

  @failingTest
  test_useOfVoidReturnInNonVoidFunctionError() async {
    // TODO(mfairhurst): Get this test to pass once codebase is compliant.
    await assertErrorsInCode('''
dynamic f(void x) {
  return x;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 36, 1),
    ]);
  }

  test_useOfVoidReturnInVoidFunctionOk() async {
    await assertNoErrorsInCode('''
void f(void x) {
  return x;
}
''');
  }

  test_useOfVoidWhenArgumentError() async {
    await assertErrorsInCode('''
void f(void x) {
  g(x);
}
void g(dynamic x) { }
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 21, 1),
    ]);
  }

  test_useOfVoidWithInitializerOk() async {
    await assertErrorsInCode('''
void f(void x) {
  void y = x;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 24, 1),
    ]);
  }

  test_variableDeclaration_function_error() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    Object a = f();
  }
}''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 41, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 45, 1),
    ]);
  }

  test_variableDeclaration_function_ok() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    void a = f();
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 39, 1),
    ]);
  }

  test_variableDeclaration_method2() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m(), b = m();
  }
}''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 47, 1),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 52, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 56, 1),
    ]);
  }

  test_variableDeclaration_method_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m();
  }
}''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 47, 1),
    ]);
  }

  test_variableDeclaration_method_ok() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    void a = m();
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 41, 1),
    ]);
  }

  test_yieldStarVoid_asyncStar() async {
    await assertErrorsInCode('''
Object? f(void x) async* {
  yield* x;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH,
          36, 1),
      error(CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE, 36, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 36, 1),
    ]);
  }

  test_yieldStarVoid_syncStar() async {
    await assertErrorsInCode('''
Object? f(void x) sync* {
  yield* x;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH,
          35, 1),
      error(CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE, 35, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 35, 1),
    ]);
  }

  test_yieldVoid_asyncStar() async {
    await assertErrorsInCode('''
dynamic f(void x) async* {
  yield x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 35, 1),
    ]);
  }

  test_yieldVoid_syncStar() async {
    await assertErrorsInCode('''
dynamic f(void x) sync* {
  yield x;
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 34, 1),
    ]);
  }
}
