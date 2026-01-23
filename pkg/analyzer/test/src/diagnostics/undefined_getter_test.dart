// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedGetterTest);
  });
}

@reflectiveTest
class UndefinedGetterTest extends PubPackageResolutionTest {
  test_compoundAssignment_hasSetter_instance() async {
    await assertErrorsInCode(
      '''
class C {
  set foo(int _) {}
}

f(C c) {
  c.foo += 1;
}
''',
      [error(diag.undefinedGetter, 46, 3)],
    );
  }

  test_compoundAssignment_hasSetter_static() async {
    await assertErrorsInCode(
      '''
class C {
  static set foo(int _) {}
}

f() {
  C.foo += 1;
}
''',
      [error(diag.undefinedGetter, 50, 3)],
    );
  }

  test_emptyName() async {
    await assertErrorsInCode(
      '''
class A {
}
main() {
  print(A().);
}
''',
      [error(diag.missingIdentifier, 33, 1)],
    );
  }

  test_extension_instance_extendedHasSetter_extensionHasGetter() async {
    await assertErrorsInCode(
      '''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;

  f() {
    this.foo;
  }
}
''',
      [error(diag.undefinedGetter, 95, 3)],
    );
  }

  test_extension_instance_undefined_hasSetter() async {
    await assertErrorsInCode(
      '''
extension E on int {
  void set foo(int _) {}
}
f() {
  0.foo;
}
''',
      [error(diag.undefinedGetter, 58, 3)],
    );
  }

  test_extension_instance_withInference() async {
    await assertErrorsInCode(
      r'''
extension E on int {}
var a = 3.v;
''',
      [error(diag.undefinedGetter, 32, 1)],
    );
  }

  test_extension_instance_withoutInference() async {
    await assertErrorsInCode(
      r'''
class C {}

extension E on C {}

f(C c) {
  c.a;
}
''',
      [error(diag.undefinedGetter, 46, 1)],
    );
  }

  test_extension_this_extendedHasSetter_extensionHasGetter() async {
    await assertErrorsInCode(
      '''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;
}

f(C c) {
  c.foo;
}
''',
      [error(diag.undefinedGetter, 93, 3)],
    );
  }

  test_functionAlias_typeInstantiated_getter() async {
    await assertErrorsInCode(
      '''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo;
}

extension E on Type {
  int get foo => 1;
}
''',
      [error(diag.undefinedGetterOnFunctionType, 58, 3)],
    );
  }

  test_functionAlias_typeInstantiated_getter_parenthesized() async {
    await assertNoErrorsInCode('''
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
    await assertNoErrorsInCode('''
f(Function f) {
  return f.call;
}
''');
  }

  test_get_from_abstract_field_final_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int x;
}
int f(A a) => a.x;
''');
  }

  test_get_from_abstract_field_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
}
int f(A a) => a.x;
''');
  }

  test_get_from_external_field_final_valid() async {
    await assertNoErrorsInCode('''
class A {
  external final int x;
}
int f(A a) => a.x;
''');
  }

  test_get_from_external_field_valid() async {
    await assertNoErrorsInCode('''
class A {
  external int x;
}
int f(A a) => a.x;
''');
  }

  test_get_from_external_static_field_final_valid() async {
    await assertNoErrorsInCode('''
class A {
  external static final int x;
}
int f() => A.x;
''');
  }

  test_get_from_external_static_field_valid() async {
    await assertNoErrorsInCode('''
class A {
  external static int x;
}
int f() => A.x;
''');
  }

  test_ifElement_inList_notPromoted() async {
    await assertErrorsInCode(
      '''
f(int x) {
  return [if (x is String) x.length];
}
''',
      [error(diag.undefinedGetter, 40, 6)],
    );
  }

  test_ifElement_inList_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return [if (x is String) x.length];
}
''');
  }

  test_ifElement_inMap_notPromoted() async {
    await assertErrorsInCode(
      '''
f(int x) {
  return {if (x is String) x : x.length};
}
''',
      [error(diag.undefinedGetter, 44, 6)],
    );
  }

  test_ifElement_inMap_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return {if (x is String) x : x.length};
}
''');
  }

  test_ifElement_inSet_notPromoted() async {
    await assertErrorsInCode(
      '''
f(int x) {
  return {if (x is String) x.length};
}
''',
      [error(diag.undefinedGetter, 40, 6)],
    );
  }

  test_ifElement_inSet_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return {if (x is String) x.length};
}
''');
  }

  test_ifStatement_notPromoted() async {
    await assertErrorsInCode(
      '''
f(int x) {
  if (x is String) {
    x.length;
  }
}
''',
      [error(diag.undefinedGetter, 38, 6)],
    );
  }

  test_ifStatement_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  if (x is String) {
    x.length;
  }
}
''');
  }

  test_instance_undefined() async {
    await assertErrorsInCode(
      r'''
class T {}
f(T e) { return e.m; }
''',
      [error(diag.undefinedGetter, 29, 1)],
    );
  }

  test_instance_undefined_mixin() async {
    await assertErrorsInCode(
      r'''
mixin M {
  f() { return this.m; }
}
''',
      [error(diag.undefinedGetter, 30, 1)],
    );
  }

  test_new_cascade() async {
    await assertErrorsInCode(
      '''
class C {}

f(C? c) {
  c..new;
}
''',
      [error(diag.undefinedGetter, 27, 3)],
    );
  }

  test_new_dynamic() async {
    await assertErrorsInCode(
      '''
f(dynamic d) {
  d.new;
}
''',
      [error(diag.undefinedGetter, 19, 3)],
    );
  }

  test_new_expression() async {
    await assertErrorsInCode(
      '''
class C {}

f(C? c1, C c2) {
  (c1 ?? c2).new;
}
''',
      [error(diag.undefinedGetter, 42, 3)],
    );
  }

  test_new_nullAware() async {
    await assertErrorsInCode(
      '''
class C {}

f(C? c) {
  c?.new;
}
''',
      [error(diag.undefinedGetter, 27, 3)],
    );
  }

  test_new_prefixedIdentifier() async {
    await assertErrorsInCode(
      '''
class C {}

abstract class D {
  C get c;
}

f(D d) {
  d.c.new;
}
''',
      [error(diag.undefinedGetter, 60, 3)],
    );
  }

  test_new_simpleIdentifier() async {
    await assertErrorsInCode(
      '''
class C {}

f(C c) {
  c.new;
}
''',
      [error(diag.undefinedGetter, 25, 3)],
    );
  }

  test_new_typeVariable() async {
    await assertErrorsInCode(
      '''
f<T>(T t) {
  t.new;
}
''',
      [error(diag.undefinedGetter, 16, 3)],
    );
  }

  test_nullMember_undefined() async {
    await assertErrorsInCode(
      r'''
m() {
  Null _null;
  _null.foo;
}
''',
      [error(diag.invalidUseOfNullValue, 28, 3)],
    );
  }

  test_object_call() async {
    await assertErrorsInCode(
      '''
f(Object o) {
  return o.call;
}
''',
      [error(diag.undefinedGetter, 25, 4)],
    );
  }

  test_promotedTypeParameter_regress35305() async {
    await assertErrorsInCode(
      r'''
void f<X extends num, Y extends X>(Y y) {
  if (y is int) {
    y.isEven;
  }
}
''',
      [error(diag.undefinedGetter, 66, 6)],
    );
  }

  test_propertyAccess_functionClass_call() async {
    await assertErrorsInCode(
      '''
void f(Function a) {
  return (a).call;
}
''',
      [error(diag.returnOfInvalidTypeFromFunction, 30, 8)],
    );
  }

  test_propertyAccess_functionType_call() async {
    await assertNoErrorsInCode('''
class A {
  void staticMethod() {}
}

void f(A a) {
  a.staticMethod.call;
}
''');
  }

  test_static_conditionalAccess_defined() async {
    await assertErrorsInCode(
      '''
class A {
  static var x;
}
var a = A?.x;
''',
      [error(diag.invalidNullAwareOperator, 37, 2)],
    );
  }

  test_static_definedInSuperclass() async {
    await assertErrorsInCode(
      '''
class S {
  static int get g => 0;
}
class C extends S {}
f(p) {
  f(C.g);
}''',
      [error(diag.undefinedGetter, 71, 1)],
    );
  }

  test_static_extension_InstanceAccess() async {
    await assertErrorsInCode(
      '''
class C {}

extension E on C {
  static int get a => 0;
}

C g(C c) => C();
f(C c) {
  g(c).a;
}
''',
      [error(diag.undefinedGetter, 92, 1)],
    );
  }

  test_static_undefined() async {
    await assertErrorsInCode(
      '''
class C {}
f(p) {
  f(C.m);
}''',
      [error(diag.undefinedGetter, 24, 1)],
    );
  }

  test_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(
      r'''
class T {
  static int get foo => 42;
}
main() {
  T..foo;
}
''',
      [error(diag.undefinedGetter, 54, 3)],
    );
  }

  test_typeLiteral_conditionalAccess() async {
    await assertErrorsInCode(
      '''
class A {}
f() => A?.hashCode;
''',
      [
        error(diag.invalidNullAwareOperator, 19, 2),
        error(diag.undefinedGetter, 21, 8),
      ],
    );
  }

  test_typeSubstitution_defined() async {
    await assertNoErrorsInCode(r'''
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
