// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfVoidResultTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UseOfVoidResultTest extends PubPackageResolutionTest {
  test_andVoidLhsError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x && true;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_andVoidRhsError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  true && x;
//        ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_assignment_toDynamic() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  // ignore:unused_local_variable
  dynamic v = x;
//            ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_assignment_toVoid() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  // ignore:unused_local_variable
  void v = x;
}
''');
  }

  test_assignmentExpression_function() async {
    await resolveTestCodeWithDiagnostics('''
void f() {}
class A {
  n() {
    var a;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    a = f();
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  }
}''');
  }

  test_assignmentExpression_method() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void m() {}
  n() {
    var a;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    a = m();
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  }
}''');
  }

  test_assignmentToVoidParameterOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  g(x);
}
void g(void x) {}
''');
  }

  test_await() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) async {
  await x;
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_awaitForIn_streamVoid_declaredVariable_nonVoid() async {
    await resolveTestCodeWithDiagnostics('''
void f(Stream<void> values) async {
  await for (Object? _ in values) {}
//                        ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  await for (dynamic _ in values) {}
//                        ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_awaitForIn_streamVoid_declaredVariable_void() async {
    await resolveTestCodeWithDiagnostics('''
void f(Stream<void> values) async {
  await for (void _ in values) {}
  await for (var _ in values) {}
}
''');
  }

  test_constructorFieldInitializer_toDynamic() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  dynamic f;
  A(void x) : f = x;
//                ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_constructorFieldInitializer_toVoid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void f;
  A(void x) : f = x;
}
''');
  }

  test_extensionApplication() async {
    await resolveTestCodeWithDiagnostics('''
extension E on String {
  int get g => 0;
}

void f() {}

void h() {
  E(f()).g;
//  ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_forIn_iterableVoid_declaredVariable_nonVoid() async {
    await resolveTestCodeWithDiagnostics('''
void f(List<void> values) {
  for (Object? _ in values) {}
//                  ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  for (dynamic _ in values) {}
//                  ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_forIn_iterableVoid_declaredVariable_void() async {
    await resolveTestCodeWithDiagnostics('''
void f(List<void> values) {
  for (void _ in values) {}
  for (var _ in values) {}
}
''');
  }

  test_forIn_iterableVoid_existingVariable_nonVoid() async {
    await resolveTestCodeWithDiagnostics('''
void f(List<void> values) {
  Object? object;
  dynamic anything;
  for (object in values) {
//               ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
    object;
  }
  for (anything in values) {
//                 ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
    anything;
  }
}
''');
  }

  test_forIn_iterableVoid_existingVariable_void() async {
    await resolveTestCodeWithDiagnostics('''
void f(List<void> values) {
  void existing = null;
  for (existing in values) {
    existing;
  }
}
''');
  }

  test_implicitReturnValue() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {}
class A {
  n() {
    var a = f();
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }

  test_inForLoop_error() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void m() {}
  n() {
    for(Object a = m();;) {}
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                 ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  }
}''');
  }

  test_inForLoop_ok() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void m() {}
  n() {
    for(void a = m();;) {}
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }

  test_interpolateVoidValueError() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void x) {
  "$x";
//  ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_negateVoidValueError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  !x;
// ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_nonVoidReturnValue() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() => 1;
g() {
  var a = f();
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_nullAwareElement_list_voidValue() async {
    await resolveTestCodeWithDiagnostics('''
void f(void value) {
  <void>[?value];
//        ^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_nullAwareElement_set_voidValue() async {
    await resolveTestCodeWithDiagnostics('''
void f(void value) {
  <void>{?value};
//        ^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_nullAwareMapEntry_nullAwareKey_voidKey() async {
    await resolveTestCodeWithDiagnostics('''
void f(void key) {
  <void, int>{?key: 0};
//             ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_nullAwareMapEntry_nullAwareKey_voidValue() async {
    await resolveTestCodeWithDiagnostics('''
void f(int? key, void value) {
  <int, void>{?key: value};
}
''');
  }

  test_nullAwareMapEntry_nullAwareValue_voidKey() async {
    await resolveTestCodeWithDiagnostics('''
void f(void key, int? value) {
  <void, int>{key: ?value};
}
''');
  }

  test_nullAwareMapEntry_nullAwareValue_voidValue() async {
    await resolveTestCodeWithDiagnostics('''
void f(void value) {
  <int, void>{0: ?value};
//                ^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_nullCheck() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(void x) {
  x!;
//^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    assertType(result.findNode.postfix('x!'), 'void');
  }

  test_orVoidLhsError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x || true;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_orVoidRhsError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  false || x;
//         ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_recordLiteral_namedField() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  (one: x,);
// ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_recordLiteral_positionalField() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  (x,);
// ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_switchStatement_expression() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  switch(x) {}
//       ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_throwVoidValueError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  throw x;
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
// [diag.throwOfInvalidType] The type 'void' of the thrown expression must be assignable to 'Object'.
}
''');
  }

  test_unaryNegativeVoidFunction() async {
    await resolveTestCodeWithDiagnostics('''
void test(void f()) {
  -f();
//^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'unary-' can't be unconditionally invoked because the receiver can be 'null'.
// ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_unaryNegativeVoidValueError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  -x;
//^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'unary-' can't be unconditionally invoked because the receiver can be 'null'.
// ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidAsIndexAssignError() async {
    await resolveTestCodeWithDiagnostics('''
void f(List list, void x) {
  list[x] = null;
//     ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidAsIndexError() async {
    await resolveTestCodeWithDiagnostics('''
void f(List list, void x) {
  list[x];
//     ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidAssignedToDynamicError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  dynamic z = x;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//            ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidByIndexingError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x[0];
// ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidCallSetterError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x.foo = null;
//  ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidCastsOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  use(x as int);
}

void use(Object? x) {}
''');
  }

  test_useOfVoidInConditionalConditionError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x ? null : null;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInConditionalLhsError() async {
    // A conditional expression is one of the allowed positions for `void`.
    await resolveTestCodeWithDiagnostics('''
void f(bool c, void x) {
  c ? x : null;
}
''');
  }

  test_useOfVoidInConditionalRhsError() async {
    // A conditional expression is one of the allowed positions for `void`.
    await resolveTestCodeWithDiagnostics('''
void f(bool c, void x) {
  c ? null : x;
}
''');
  }

  test_useOfVoidInDoWhileConditionError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  do {} while (x);
//             ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInExpStmtOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x;
}
''');
  }

  test_useOfVoidInForeachIterableError() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void x, y) {
  for (y in x) {}
//          ^
// [diag.uncheckedUseOfNullableValueAsIterator] A nullable expression can't be used as an iterator in a for-in loop.
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInForeachIterableError_declaredVariable() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  for (var v in x) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
//              ^
// [diag.uncheckedUseOfNullableValueAsIterator] A nullable expression can't be used as an iterator in a for-in loop.
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  @SkippedTest() // TODO(scheglov): review this
  test_useOfVoidInForeachVariableError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  for (x in [1, 2]) {}
//     ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInForPartsOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  for (x; true; x) {}
}
''');
  }

  test_useOfVoidInIsTestError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x is int;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInListLiteralError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  <dynamic>[x];
//          ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInListLiteralOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  [x];
}
''');
  }

  test_useOfVoidInMapLiteralKeyError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  <dynamic, int>{x : 4};
//               ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInMapLiteralKeyOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  ({x : 4});
}
''');
  }

  test_useOfVoidInMapLiteralValueError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  <int, dynamic>{4: x};
//                  ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInMapLiteralValueOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  ({4: x});
}
''');
  }

  test_useOfVoidInNullOperatorLhsError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x ?? 1;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInNullOperatorRhsOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  null ?? x;
}
''');
  }

  test_useOfVoidInSpecialAssignmentError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x += 1;
//  ^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidInWhileConditionError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  while (x) {};
//       ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidNullPropertyAccessError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x?.foo;
//   ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidPropertyAccessError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x.foo;
//  ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_useOfVoidReturnInExtensionMethod() async {
    await resolveTestCodeWithDiagnostics('''
extension on void {
  testVoid() {
//^^^^^^^^
// [diag.unusedElement] The declaration 'testVoid' isn't referenced.
    // No access on void. Static type of `this` is void!
    this.toString();
//  ^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  }
}
''');
  }

  @SkippedTest() // TODO(scheglov): review this
  test_useOfVoidReturnInNonVoidFunctionError() async {
    // TODO(mfairhurst): Get this test to pass once codebase is compliant.
    await resolveTestCodeWithDiagnostics('''
dynamic f(void x) {
  return x;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'void' can't be returned from the function 'f' because it has a return type of 'dynamic'.
}
''');
  }

  test_useOfVoidReturnInVoidFunctionOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  return x;
}
''');
  }

  test_useOfVoidWhenArgumentError() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  g(x);
//  ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
void g(dynamic x) { }
''');
  }

  test_useOfVoidWithInitializerOk() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  void y = x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
  }

  test_variableDeclaration_function_error() async {
    await resolveTestCodeWithDiagnostics('''
void f() {}
class A {
  n() {
    Object a = f();
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//             ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  }
}''');
  }

  test_variableDeclaration_function_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f() {}
class A {
  n() {
    void a = f();
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }

  test_variableDeclaration_method2() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void m() {}
  n() {
    Object a = m(), b = m();
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//             ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
//                      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  }
}''');
  }

  test_variableDeclaration_method_error() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void m() {}
  n() {
    Object a = m();
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//             ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
  }
}''');
  }

  test_variableDeclaration_method_ok() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void m() {}
  n() {
    void a = m();
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }

  test_yieldStarVoid_asyncStar() async {
    await resolveTestCodeWithDiagnostics('''
Object? f(void x) async* {
  yield* x;
//       ^
// [diag.uncheckedUseOfNullableValueInYieldEach] A nullable expression can't be used in a yield-each statement.
// [diag.yieldEachOfInvalidType] The type 'void' implied by the 'yield*' expression must be assignable to 'Object'.
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_yieldStarVoid_syncStar() async {
    await resolveTestCodeWithDiagnostics('''
Object? f(void x) sync* {
  yield* x;
//       ^
// [diag.uncheckedUseOfNullableValueInYieldEach] A nullable expression can't be used in a yield-each statement.
// [diag.yieldEachOfInvalidType] The type 'void' implied by the 'yield*' expression must be assignable to 'Object'.
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_yieldVoid_asyncStar() async {
    await resolveTestCodeWithDiagnostics('''
dynamic f(void x) async* {
  yield x;
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_yieldVoid_syncStar() async {
    await resolveTestCodeWithDiagnostics('''
dynamic f(void x) sync* {
  yield x;
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }
}
