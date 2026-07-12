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
  test_argumentList_argument_parameterTypeDynamic_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  g(x);
//  ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
void g(dynamic x) { }
''');
  }

  test_argumentList_argument_parameterTypeVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  g(x);
}
void g(void x) {}
''');
  }

  test_asExpression_expression_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  use(x as int);
}

void use(Object? x) {}
''');
  }

  test_assignmentExpression_compound_read_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x += 1;
//  ^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_assignmentExpression_simple_propertyAccess_target_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x.foo = null;
//  ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_assignmentExpression_simple_rightHandSide_function_toLocalVariableTypeDynamic_error() async {
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

  test_assignmentExpression_simple_rightHandSide_method_toLocalVariableTypeDynamic_error() async {
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

  test_awaitExpression_expression_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) async {
  await x;
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_awaitForIn_streamElementTypeVoid_variableTypeNonVoid_error() async {
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

  test_awaitForIn_streamElementTypeVoid_variableTypeVoidOrInferred_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(Stream<void> values) async {
  await for (void _ in values) {}
  await for (var _ in values) {}
}
''');
  }

  test_binaryExpression_ifNull_leftOperand_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x ?? 1;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_binaryExpression_ifNull_rightOperand_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  null ?? x;
}
''');
  }

  test_binaryExpression_logicalAnd_leftOperand_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x && true;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_binaryExpression_logicalAnd_rightOperand_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  true && x;
//        ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_binaryExpression_logicalOr_leftOperand_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x || true;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_binaryExpression_logicalOr_rightOperand_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  false || x;
//         ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_conditionalExpression_condition_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x ? null : null;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_conditionalExpression_elseExpression_ok() async {
    // A conditional expression is one of the allowed positions for `void`.
    await resolveTestCodeWithDiagnostics('''
void f(bool c, void x) {
  c ? null : x;
}
''');
  }

  test_conditionalExpression_thenExpression_ok() async {
    // A conditional expression is one of the allowed positions for `void`.
    await resolveTestCodeWithDiagnostics('''
void f(bool c, void x) {
  c ? x : null;
}
''');
  }

  test_constructorFieldInitializer_fieldTypeDynamic_error() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  dynamic f;
  A(void x) : f = x;
//                ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_constructorFieldInitializer_fieldTypeVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void f;
  A(void x) : f = x;
}
''');
  }

  test_doStatement_condition_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  do {} while (x);
//             ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_expressionStatement_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x;
}
''');
  }

  test_extensionOnVoid_this_error() async {
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

  test_extensionOverride_argument_error() async {
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

  test_forIn_iterable_typeVoid_declaredVariable_error() async {
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

  test_forIn_iterable_typeVoid_error() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void x, y) {
  for (y in x) {}
//          ^
// [diag.uncheckedUseOfNullableValueAsIterator] A nullable expression can't be used as an iterator in a for-in loop.
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_forIn_iterableElementTypeVoid_declaredVariableTypeNonVoid_error() async {
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

  test_forIn_iterableElementTypeVoid_declaredVariableTypeVoidOrInferred_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(List<void> values) {
  for (void _ in values) {}
  for (var _ in values) {}
}
''');
  }

  test_forIn_iterableElementTypeVoid_existingVariableTypeNonVoid_error() async {
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

  test_forIn_iterableElementTypeVoid_existingVariableTypeVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(List<void> values) {
  void existing = null;
  for (existing in values) {
    existing;
  }
}
''');
  }

  @FailingTest() // TODO(scheglov): review this
  test_forIn_loopVariable_typeVoid_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  for (x in [1, 2]) {}
//     ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_forPartsWithDeclarations_initializer_toObject_error() async {
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

  test_forPartsWithDeclarations_initializer_toVoid_ok() async {
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

  test_forPartsWithExpression_initializationAndUpdaters_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  for (x; true; x) {}
}
''');
  }

  test_indexExpression_index_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(List list, void x) {
  list[x];
//     ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_indexExpression_index_inAssignment_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(List list, void x) {
  list[x] = null;
//     ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_indexExpression_target_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x[0];
// ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_interpolationExpression_expression_error() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void x) {
  "$x";
//  ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_isExpression_expression_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x is int;
//^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_listLiteral_topLevelElement_toDynamic_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  <dynamic>[x];
//          ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_listLiteral_topLevelElement_toVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  [x];
}
''');
  }

  test_mapLiteral_topLevelKey_toDynamic_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  <dynamic, int>{x : 4};
//               ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_mapLiteral_topLevelKey_toVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  ({x : 4});
}
''');
  }

  test_mapLiteral_topLevelValue_toDynamic_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  <int, dynamic>{4: x};
//                  ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_mapLiteral_topLevelValue_toVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  ({4: x});
}
''');
  }

  test_mapLiteralEntry_keyQuestion_keyTypeVoid_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void key) {
  <void, int>{?key: 0};
//             ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_mapLiteralEntry_keyQuestion_valueTypeVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(int? key, void value) {
  <int, void>{?key: value};
}
''');
  }

  test_mapLiteralEntry_valueQuestion_keyTypeVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void key, int? value) {
  <void, int>{key: ?value};
}
''');
  }

  test_mapLiteralEntry_valueQuestion_valueTypeVoid_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void value) {
  <int, void>{0: ?value};
//                ^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_nullAwareElement_list_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void value) {
  <void>[?value];
//        ^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_nullAwareElement_set_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void value) {
  <void>{?value};
//        ^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_postfixExpression_bang_operand_error() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(void x) {
  x!;
//^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    assertType(result.findNode.postfix('x!'), 'void');
  }

  test_prefixExpression_bang_operand_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  !x;
// ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_prefixExpression_minus_identifier_error() async {
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

  test_prefixExpression_minus_invocation_error() async {
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

  test_propertyAccess_nullAware_target_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x?.foo;
//   ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_propertyAccess_target_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x.foo;
//  ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_recordLiteral_namedField_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  (one: x,);
// ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_recordLiteral_positionalField_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  (x,);
// ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  @FailingTest() // TODO(scheglov): review this
  test_returnStatement_nonVoidFunction_error() async {
    // TODO(mfairhurst): Get this test to pass once codebase is compliant.
    await resolveTestCodeWithDiagnostics('''
dynamic f(void x) {
  return x;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'void' can't be returned from the function 'f' because it has a return type of 'dynamic'.
}
''');
  }

  test_returnStatement_voidFunction_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  return x;
}
''');
  }

  test_switchStatement_expression_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  switch(x) {}
//       ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_throwExpression_expression_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  throw x;
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
// [diag.throwOfInvalidType] The type 'void' of the thrown expression must be assignable to 'Object'.
}
''');
  }

  test_variableDeclaration_initializer_function_toObject_error() async {
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

  test_variableDeclaration_initializer_function_toVoid_ok() async {
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

  test_variableDeclaration_initializer_implicitReturn_ok() async {
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

  test_variableDeclaration_initializer_method_multiple_error() async {
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

  test_variableDeclaration_initializer_method_toObject_error() async {
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

  test_variableDeclaration_initializer_method_toVoid_ok() async {
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

  test_variableDeclaration_initializer_nonVoidReturn_ok() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() => 1;
g() {
  var a = f();
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_variableDeclaration_initializer_toDynamic_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  // ignore:unused_local_variable
  dynamic v = x;
//            ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_variableDeclaration_initializer_toDynamic_withUnusedLocal_error() async {
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

  test_variableDeclaration_initializer_toVoid_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  // ignore:unused_local_variable
  void v = x;
}
''');
  }

  test_variableDeclaration_initializer_toVoid_withUnusedLocal_ok() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  void y = x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
  }

  test_whileStatement_condition_error() async {
    await resolveTestCodeWithDiagnostics('''
void f(void x) {
  while (x) {};
//       ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_yieldStatement_asyncStar_error() async {
    await resolveTestCodeWithDiagnostics('''
dynamic f(void x) async* {
  yield x;
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }

  test_yieldStatement_star_asyncStar_error() async {
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

  test_yieldStatement_star_syncStar_error() async {
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

  test_yieldStatement_syncStar_error() async {
    await resolveTestCodeWithDiagnostics('''
dynamic f(void x) sync* {
  yield x;
//      ^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
  }
}
