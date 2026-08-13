// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedGetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedGetterTest extends PubPackageResolutionTest {
  test_compoundAssignment_hasSetter_instance() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  set foo(int _) {}
}

f(C c) {
  c.foo += 1;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'C'.
}
''');
  }

  test_compoundAssignment_hasSetter_static() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  static set foo(int _) {}
}

f() {
  C.foo += 1;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'C'.
}
''');
  }

  test_emptyName() async {
    await resolveTestCodeWithDiagnostics('''
class A {
}
main() {
  print(A().);
//          ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_extension_instance_extendedHasSetter_extensionHasGetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;

  f() {
    this.foo;
//       ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'C'.
  }
}
''');
  }

  test_extension_instance_undefined_hasSetter() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  void set foo(int _) {}
}
f() {
  0.foo;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'int'.
}
''');
  }

  test_extension_instance_withInference() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {}
var a = 3.v;
//        ^
// [diag.undefinedGetter] The getter 'v' isn't defined for the type 'int'.
''');
  }

  test_extension_instance_withoutInference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E on C {}

f(C c) {
  c.a;
//  ^
// [diag.undefinedGetter] The getter 'a' isn't defined for the type 'C'.
}
''');
  }

  test_extension_this_extendedHasSetter_extensionHasGetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;
}

f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'C'.
}
''');
  }

  test_functionAlias_typeInstantiated_getter() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo;
//        ^^^
// [diag.undefinedGetterOnFunctionType] The getter 'foo' isn't defined for the 'Fn' function type.
}

extension E on Type {
  int get foo => 1;
}
''');
  }

  test_functionAlias_typeInstantiated_getter_parenthesized() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo;
}

extension E on Type {
  int get foo => 1;
}
''');
  }

  test_generic_function_call() async {
    // Referencing `.call` on a `Function` type works similarly to referencing
    // it on `dynamic`--the reference is accepted at compile time, and all type
    // checking is deferred until runtime.
    await resolveTestCodeWithDiagnostics('''
f(Function f) {
  return f.call;
}
''');
  }

  test_get_from_abstract_field_final_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final int x;
}
int f(A a) => a.x;
''');
  }

  test_get_from_abstract_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
int f(A a) => a.x;
''');
  }

  test_get_from_external_field_final_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int x;
}
int f(A a) => a.x;
''');
  }

  test_get_from_external_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
int f(A a) => a.x;
''');
  }

  test_get_from_external_static_field_final_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static final int x;
}
int f() => A.x;
''');
  }

  test_get_from_external_static_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static int x;
}
int f() => A.x;
''');
  }

  test_ifElement_inList_notPromoted() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  return [if (x is String) x.length];
//                           ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'int'.
}
''');
  }

  test_ifElement_inList_promoted() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  return [if (x is String) x.length];
}
''');
  }

  test_ifElement_inMap_notPromoted() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  return {if (x is String) x : x.length};
//                               ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'int'.
}
''');
  }

  test_ifElement_inMap_promoted() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  return {if (x is String) x : x.length};
}
''');
  }

  test_ifElement_inSet_notPromoted() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  return {if (x is String) x.length};
//                           ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'int'.
}
''');
  }

  test_ifElement_inSet_promoted() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  return {if (x is String) x.length};
}
''');
  }

  test_ifStatement_notPromoted() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  if (x is String) {
    x.length;
//    ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'int'.
  }
}
''');
  }

  test_ifStatement_promoted() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  if (x is String) {
    x.length;
  }
}
''');
  }

  test_instance_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class T {}
f(T e) { return e.m; }
//                ^
// [diag.undefinedGetter] The getter 'm' isn't defined for the type 'T'.
''');
  }

  test_instance_undefined_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  f() { return this.m; }
//                  ^
// [diag.undefinedGetter] The getter 'm' isn't defined for the type 'M'.
}
''');
  }

  test_new_cascade() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c) {
  c..new;
//   ^^^
// [diag.undefinedGetter] The getter 'new' isn't defined for the type 'C?'.
}
''');
  }

  test_new_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f(dynamic d) {
  d.new;
//  ^^^
// [diag.undefinedGetter] The getter 'new' isn't defined for the type 'dynamic'.
}
''');
  }

  test_new_expression() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c1, C c2) {
  (c1 ?? c2).new;
//           ^^^
// [diag.undefinedGetter] The getter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_new_nullAware() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c) {
  c?.new;
//   ^^^
// [diag.undefinedGetter] The getter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_new_prefixedIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

abstract class D {
  C get c;
}

f(D d) {
  d.c.new;
//    ^^^
// [diag.undefinedGetter] The getter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_new_simpleIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C c) {
  c.new;
//  ^^^
// [diag.undefinedGetter] The getter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_new_typeVariable() async {
    await resolveTestCodeWithDiagnostics('''
f<T>(T t) {
  t.new;
//  ^^^
// [diag.undefinedGetter] The getter 'new' isn't defined for the type 'T'.
}
''');
  }

  test_nullMember_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null _null;
  _null.foo;
//      ^^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_object_call() async {
    await resolveTestCodeWithDiagnostics('''
f(Object o) {
  return o.call;
//         ^^^^
// [diag.undefinedGetter] The getter 'call' isn't defined for the type 'Object'.
}
''');
  }

  test_promotedTypeParameter_regress35305() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<X extends num, Y extends X>(Y y) {
  if (y is int) {
    y.isEven;
//    ^^^^^^
// [diag.undefinedGetter] The getter 'isEven' isn't defined for the type 'Y'.
  }
}
''');
  }

  test_propertyAccess_functionClass_call() async {
    await resolveTestCodeWithDiagnostics('''
void f(Function a) {
  return (a).call;
//       ^^^^^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Function' can't be returned from the function 'f' because it has a return type of 'void'.
}
''');
  }

  test_propertyAccess_functionType_call() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void staticMethod() {}
}

void f(A a) {
  a.staticMethod.call;
}
''');
  }

  test_static_conditionalAccess_defined() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static var x;
}
var a = A?.x;
//       ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
''');
  }

  test_static_definedInSuperclass() async {
    await resolveTestCodeWithDiagnostics('''
class S {
  static int get g => 0;
}
class C extends S {}
f(p) {
  f(C.g);
//    ^
// [diag.undefinedGetter] The getter 'g' isn't defined for the type 'C'.
}''');
  }

  test_static_extension_InstanceAccess() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

extension E on C {
  static int get a => 0;
}

C g(C c) => C();
f(C c) {
  g(c).a;
//     ^
// [diag.undefinedGetter] The getter 'a' isn't defined for the type 'C'.
}
''');
  }

  test_static_undefined() async {
    await resolveTestCodeWithDiagnostics('''
class C {}
f(p) {
  f(C.m);
//    ^
// [diag.undefinedGetter] The getter 'm' isn't defined for the type 'C'.
}''');
  }

  test_typeLiteral_cascadeTarget() async {
    await resolveTestCodeWithDiagnostics(r'''
class T {
  static int get foo => 42;
}
main() {
  T..foo;
//   ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'Type'.
}
''');
  }

  test_typeLiteral_conditionalAccess() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
f() => A?.hashCode;
//      ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
//        ^^^^^^^^
// [diag.undefinedGetter] The getter 'hashCode' isn't defined for the type 'A'.
''');
  }

  test_typeSubstitution_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  E element;
  A(this.element);
}
class B extends A<List> {
  B(List element) : super(element);
  m() {
    element.last;
  }
}
''');
  }
}
