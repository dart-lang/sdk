// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAssignment_ImplicitCallReferenceTest);
    defineReflectiveTests(InvalidAssignmentTest);
    defineReflectiveTests(InvalidAssignmentWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidAssignment_ImplicitCallReferenceTest
    extends PubPackageResolutionTest {
  test_invalid_genericBoundedCall_nonGenericContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T extends num>(T t) => t;
}

String Function(String) f = C();
//                          ^^^
// [diag.invalidAssignment] A value of type 'num Function(num)' can't be assigned to a variable of type 'String Function(String)'.
''');
  }

  test_invalid_genericCall_genericEnclosingClass_nonGenericContext() async {
    // The type arguments of the instance of `C` should be accurate and be
    // taken into account when evaluating the assignment of the implicit call
    // reference.
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T a);
  void call<U>(T t, U u) {}
}

void Function(bool, String) f = C(7);
//                              ^^^^
// [diag.invalidAssignment] A value of type 'void Function(int, dynamic)' can't be assigned to a variable of type 'void Function(bool, String)'.
''');
  }

  test_invalid_genericCall_nonGenericContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T>(T t) => t;
}

void Function() f = C();
//                  ^^^
// [diag.invalidAssignment] A value of type 'dynamic Function(dynamic)' can't be assigned to a variable of type 'void Function()'.
''');
  }

  test_invalid_genericCall_nonGenericContext_withoutConstructorTearoffs() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  T call<T>(T t) => t;
}

int Function(int) f = C();
//                    ^^^
// [diag.invalidAssignment] A value of type 'T Function<T>(T)' can't be assigned to a variable of type 'int Function(int)'.
''');
  }

  test_invalid_interfaceType_enum_interfaces() async {
    await resolveTestCodeWithDiagnostics(r'''
class I {}
class J {}
enum E implements J {
  v
}
I x = E.v;
//    ^^^
// [diag.invalidAssignment] A value of type 'E' can't be assigned to a variable of type 'I'.
''');
  }

  test_invalid_message_preferTypeAlias_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = T Function();

void f(A<int> a) {
  A<String> b = a;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
//              ^
// [diag.invalidAssignment] A value of type 'A<int>' can't be assigned to a variable of type 'A<String>'.
}
''');
  }

  test_invalid_message_preferTypeAlias_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = List<T>;

void f(A<int> a) {
  A<String> b = a;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
//              ^
// [diag.invalidAssignment] A value of type 'A<int>' can't be assigned to a variable of type 'A<String>'.
}
''');
  }

  test_invalid_message_preferTypeAlias_recordType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = (T, T);

void f(A<int> a) {
  A<String> b = a;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
//              ^
// [diag.invalidAssignment] A value of type 'A<int>' can't be assigned to a variable of type 'A<String>'.
}
''');
  }

  test_invalid_noCall_functionContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

Function f = C();
//           ^^^
// [diag.invalidAssignment] A value of type 'C' can't be assigned to a variable of type 'Function'.
''');
  }

  test_invalid_noCall_functionTypeContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

String Function(String) f = C();
//                          ^^^
// [diag.invalidAssignment] A value of type 'C' can't be assigned to a variable of type 'String Function(String)'.
''');
  }

  test_invalid_nonGenericCall() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int a) {}
}

void Function(String) f = C();
//                        ^^^
// [diag.invalidAssignment] A value of type 'void Function(int)' can't be assigned to a variable of type 'void Function(String)'.
''');
  }

  test_invalid_nonGenericCall_typeVariableExtendsFunctionContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int a) {}
}
class D<U extends Function> {
  U f = C();
//      ^^^
// [diag.invalidAssignment] A value of type 'C' can't be assigned to a variable of type 'U'.
}
''');
  }

  test_invalid_nonGenericCall_typeVariableExtendsFunctionTypeContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int a) {}
}
class D<U extends void Function(int)> {
  U f = C();
//      ^^^
// [diag.invalidAssignment] A value of type 'C' can't be assigned to a variable of type 'U'.
}
''');
  }

  test_valid_genericBoundedCall_nonGenericContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T extends num>(T t) => t;
}

int Function(int) f = C();
''');
  }

  test_valid_genericCall_functionContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T>(T t) => t;
}

Function f = C();
''');
  }

  test_valid_genericCall_futureOrFunctionContext() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class C {
  T call<T>(T t) => t;
}

FutureOr<Function> f = C();
''');
  }

  test_valid_genericCall_futureOrFunctionTypeContext_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class C {
  T call<T>(T t) => t;
}

FutureOr<T Function<T>(T)> f = C();
''');
  }

  test_valid_genericCall_futureOrFunctionTypeContext_nonGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class C {
  T call<T>(T t) => t;
}

FutureOr<int Function(int)> f = C();
''');
  }

  test_valid_genericCall_genericContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T>(T t) => t;
}

T Function<T>(T) f = C();
''');
  }

  test_valid_genericCall_genericEnclosingClass_nonGenericContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T a);
  void call<U>(T t, U u) {}
}

void Function(int, String) f = C(7);
''');
  }

  test_valid_genericCall_genericTypedefContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T>(T t) => t;
}
typedef Fn<T> = T Function(T);
class D<U> {
  Fn<U> f = C();
}

''');
  }

  test_valid_genericCall_nonGenericContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T>(T t) => t;
}

int Function(int) f = C();
''');
  }

  test_valid_genericCall_nullableFunctionContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T>(T t) => t;
}

Function? f = C();
''');
  }

  test_valid_genericCall_nullableNonGenericContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T>(T t) => t;
}

int Function(int)? f = C();
''');
  }

  test_valid_genericCall_typedefOfGenericContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T call<T>(T t) => t;
}

typedef Fn = T Function<T>(T);

Fn f = C();
''');
  }

  test_valid_interfaceType_enum_interfaces() async {
    await resolveTestCodeWithDiagnostics(r'''
class I {}
enum E implements I {
  v
}
I x = E.v;
''');
  }

  test_valid_nonGenericCall() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int a) {}
}

void Function(int) f = C();
''');
  }

  test_valid_nonGenericCall_declaredOnMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void call(int a) {}
}
class C with M {}

Function f = C();
''');
  }

  test_valid_nonGenericCall_inCascade() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int a) {}
}
class D {
  late void Function(int) f;
}

void foo() {
  D()..f = C();
}
''');
  }

  test_valid_nonGenericCall_subTypeViaParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(num a) {}
}

void Function(int) f = C();
''');
  }

  test_valid_nonGenericCall_subTypeViaReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int call() => 7;
}

num Function() f = C();
''');
  }
}

@reflectiveTest
class InvalidAssignmentTest extends PubPackageResolutionTest {
  test_assignment_to_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var g;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
  g = () => 0;
}
''');
  }

  test_cascadeExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  // ignore:unused_local_variable
  String v = (a)..isEven;
//            ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
}
''');
  }

  test_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
class byte {
  int _value;
//    ^^^^^^
// [diag.unusedField] The value of the field '_value' isn't used.
  byte(this._value);
  byte operator +(int val) { return this; }
}

void main() {
  byte b = new byte(52);
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  b += 3;
}
''');
  }

  test_constructorTearoff_inferredTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T a);
}

var g = C<int>.new;
''');
  }

  test_constructorTearoff_withExplicitTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T a);
}

C Function(int) g = C<int>.new;
''');
  }

  test_constructorTearoff_withExplicitTypeArgs_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T a);
}

C Function(String) g = C<int>.new;
//                     ^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'C<int> Function(int)' can't be assigned to a variable of type 'C<dynamic> Function(String)'.
''');
  }

  test_defaultValue_named() async {
    await resolveTestCodeWithDiagnostics(r'''
f({String x = 0}) {
//            ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
}
''');
  }

  test_defaultValue_named_sameType() async {
    await resolveTestCodeWithDiagnostics(r'''
f({String x = '0'}) {
}''');
  }

  test_defaultValue_optional() async {
    await resolveTestCodeWithDiagnostics(r'''
f([String x = 0]) {
//            ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
}''');
  }

  test_defaultValue_optional_sameType() async {
    await resolveTestCodeWithDiagnostics(r'''
f([String x = '0']) {
}
''');
  }

  test_functionExpressionInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  String x = (() => 5)();
//           ^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
}
''');
  }

  void
  test_functionInstantiation_topLevelVariable_genericContext_assignable() async {
    await resolveTestCodeWithDiagnostics(r'''
T f<T>(T a) => a;
U Function<U>(U) foo = f;
''');
  }

  void
  test_functionInstantiation_topLevelVariable_genericContext_nonAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
T f<T>(T a) => a;
U Function<U>(U, int) foo = f;
//                          ^
// [diag.invalidAssignment] A value of type 'T Function<T>(T)' can't be assigned to a variable of type 'U Function<U>(U, int)'.
''');
  }

  void
  test_functionInstantiation_topLevelVariable_nonGenericContext_assignable() async {
    await resolveTestCodeWithDiagnostics(r'''
T f<T>(T a) => a;
int Function(int) foo = f;
''');
  }

  void
  test_functionInstantiation_topLevelVariable_nonGenericContext_nonAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
T f<T>(T a) => a;
int Function(int, int) foo = f;
//                           ^
// [diag.invalidAssignment] A value of type 'dynamic Function(dynamic)' can't be assigned to a variable of type 'int Function(int, int)'.
''');
  }

  test_functionTearoff_genericInstantiation() async {
    var result = await resolveTestCodeWithDiagnostics('''
int Function() foo(int Function<T extends int>() f) {
  return f;
}
''');

    var node = result.findNode.functionReference('f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::foo::@formalParameter::f
    staticType: int Function<T extends int>()
  staticType: int Function()
  typeArgumentTypes
    int
''');
  }

  test_functionTearoff_inferredTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}

var g = f<int>;
''');
  }

  test_functionTearoff_withExplicitTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}

void Function(int) g = f<int>;
''');
  }

  test_functionTearoff_withExplicitTypeArgs_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}

void Function(String) g = f<int>;
//                        ^^^^^^
// [diag.invalidAssignment] A value of type 'void Function(int)' can't be assigned to a variable of type 'void Function(String)'.
''');
  }

  test_ifNullAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int i) {
  double? d;
  d ??= i;
//      ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'double?'.
}
''');
  }

  test_ifNullAssignment_sameType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int i) {
  int? j;
  j ??= i;
}
''');
  }

  test_ifNullAssignment_superType() async {
    await resolveTestCodeWithDiagnostics('''
void f(int i) {
  num? n;
  n ??= i;
}
''');
  }

  test_implicitlyImplementFunctionViaCall_1() async {
    // issue 18341
    //
    // This test and
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()' are
    // closely related: here we see that 'I' checks as a subtype of 'IntToInt'.
    await resolveTestCodeWithDiagnostics(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new I();
''');
  }

  test_implicitlyImplementFunctionViaCall_2() async {
    // issue 18341
    //
    // Here 'C' checks as a subtype of 'I', but 'C' does not check as a subtype
    // of 'IntToInt'. Together with
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_1()' we see
    // that subtyping is not transitive here.
    await resolveTestCodeWithDiagnostics(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new C();
''');
  }

  test_implicitlyImplementFunctionViaCall_3() async {
    // issue 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()', but
    // uses type 'Function' instead of more precise type 'IntToInt' for 'f'.
    await resolveTestCodeWithDiagnostics(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
Function f = new C();
''');
  }

  test_implicitlyImplementFunctionViaCall_4() async {
    // issue 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()', but
    // uses type 'VoidToInt' instead of more precise type 'IntToInt' for 'f'.
    //
    // Here 'C <: IntToInt <: VoidToInt', but the spec gives no transitivity
    // rule for '<:'. However, many of the :/tools/test.py tests assume this
    // transitivity for 'JsBuilder' objects, assigning them to
    // '(String) -> dynamic'. The declared type of 'JsBuilder.call' is
    // '(String, [dynamic]) -> Expression'.
    await resolveTestCodeWithDiagnostics(r'''
class I {
  int call([int x = 7]) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int VoidToInt();
VoidToInt f = new C();
''');
  }

  test_instanceVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 7;
}
f(y) {
  A a = A();
  if (y is String) {
    a.x = y;
//        ^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  }
}
''');
  }

  test_invalidAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  var y;
  x = y;
}
''');
  }

  test_localLevelVariable_never_null() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x = null;
//    ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Never'.
}
''');
  }

  test_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  int x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = '0';
//    ^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_localVariable_promotion() async {
    await resolveTestCodeWithDiagnostics(r'''
f(y) {
  if (y is String) {
    int x = y;
//          ^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
    print(x);
  }
}
''');
  }

  test_parenthesizedExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  // ignore:unused_local_variable
  String v = (a);
//            ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
}
''');
  }

  test_postfixExpression_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  B operator+(_) => new B();
}

class B {}

f(A a) {
  a++;
//^^^
// [diag.invalidAssignment] A value of type 'B' can't be assigned to a variable of type 'A'.
}
''');
  }

  test_postfixExpression_localVariable_sameType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator+(_) => this;
}

f(A a) {
  a++;
}
''');
  }

  test_postfixExpression_property() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  B operator+(_) => new B();
}

class B {}

class C {
  A a = A();
}

f(C c) {
  c.a++;
//^^^^^
// [diag.invalidAssignment] A value of type 'B' can't be assigned to a variable of type 'A'.
}
''');
  }

  test_postfixExpression_property_sameType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator+(_) => this;
}

class C {
  A a = A();
}

f(C c) {
  c.a++;
}
''');
  }

  test_prefixExpression_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  B operator+(_) => new B();
}

class B {}

f(A a) {
  ++a;
//^^^
// [diag.invalidAssignment] A value of type 'B' can't be assigned to a variable of type 'A'.
}
''');
  }

  test_prefixExpression_localVariable_sameType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator+(_) => this;
}

f(A a) {
  ++a;
}
''');
  }

  test_prefixExpression_property() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  B operator+(_) => new B();
}

class B {}

class C {
  A a = A();
}

f(C c) {
  ++c.a;
//^^^^^
// [diag.invalidAssignment] A value of type 'B' can't be assigned to a variable of type 'A'.
}
''');
  }

  test_prefixExpression_property_sameType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator+(_) => this;
}

class C {
  A a = A();
}

f(C c) {
  ++c.a;
}
''');
  }

  test_promotedTypeParameter_regress35306() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class C extends D {}
class D {}

void f<X extends A, Y extends B>(X x) {
  if (x is Y) {
    A a = x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    B b = x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
    X x2 = x;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'x2' isn't used.
    Y y = x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }
}
''');
  }

  void test_recordType_localVariable_initializer() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  (int, int) r = (a: 1, b: 2);
//               ^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type '({int a, int b})' can't be assigned to a variable of type '(int, int)'.
  print(r);
}
''');
  }

  void test_recordType_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int a, int b) r) {
  r = (a: 1, b: 2);
//    ^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type '({int a, int b})' can't be assigned to a variable of type '(int, int)'.
}
''');
  }

  void test_recordType_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(C c) {
  c.r = (a: 1, b: 2);
//      ^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type '({int a, int b})' can't be assigned to a variable of type '(int, int)?'.
}
class C {
  (int, int)? r;
}
''');
  }

  test_regressionInIssue18468Fix() async {
    // https://code.google.com/p/dart/issues/detail?id=18628
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T t = int;
//      ^^^
// [diag.invalidAssignment] A value of type 'Type' can't be assigned to a variable of type 'T'.
}
''');
  }

  test_staticVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int x = 1;
}
f() {
  A.x = '0';
//      ^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_staticVariable_promoted() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int x = 7;
}
f(y) {
  if (y is String) {
    A.x = y;
//        ^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  }
}
''');
  }

  test_topLevelVariable_never_null() async {
    await resolveTestCodeWithDiagnostics(r'''
Never x = throw 0;

void f() {
  x = null;
//    ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Never'.
}
''');
  }

  test_topLevelVariableDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
int x = 'string';
//      ^^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
''');
  }

  test_typeParameter() async {
    // https://github.com/dart-lang/sdk/issues/14221
    await resolveTestCodeWithDiagnostics(r'''
class B<T> {
  T? value;
  void test(num n) {
    value = n;
//          ^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T?'.
  }
}
''');
  }

  test_typeParameterRecursion_regress35306() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class C extends D {}
class D {}

void f<X extends A, Y extends B>(X x) {
  if (x is Y) {
    D d = x;
//        ^
// [diag.invalidAssignment] A value of type 'X & Y' can't be assigned to a variable of type 'D'.
    print(d);
  }
}
''');
  }

  test_variableDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 'string';
//        ^^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_variableDeclaration_overriddenOperator() async {
    // https://github.com/dart-lang/sdk/issues/17971
    await resolveTestCodeWithDiagnostics(r'''
class Point {
  final num x, y;
  Point(this.x, this.y);
  Point operator +(Point other) {
    return new Point(x+other.x, y+other.y);
  }
}
main() {
  var p1 = new Point(0, 0);
  var p2 = new Point(10, 10);
  int n = p1 + p2;
//        ^^^^^^^
// [diag.invalidAssignment] A value of type 'Point' can't be assigned to a variable of type 'int'.
  print(n);
}
''');
  }
}

@reflectiveTest
class InvalidAssignmentWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_functionType() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
dynamic a;
void Function(int i) f = a;
//                       ^
// [diag.invalidAssignment] A value of type 'dynamic' can't be assigned to a variable of type 'void Function(int)'.
''');
  }

  test_interfaceType() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
dynamic a;
int b = a;
//      ^
// [diag.invalidAssignment] A value of type 'dynamic' can't be assigned to a variable of type 'int'.
''');
  }

  test_recordType() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
dynamic a;
(int i, ) r = a;
//            ^
// [diag.invalidAssignment] A value of type 'dynamic' can't be assigned to a variable of type '(int,)'.
''');
  }
}
