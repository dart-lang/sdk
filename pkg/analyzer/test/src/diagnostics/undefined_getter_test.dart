// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedGetterTest);
    defineReflectiveTests(UndefinedGetterWithNullSafetyTest);
  });
}

@reflectiveTest
class UndefinedGetterTest extends PubPackageResolutionTest
    with UndefinedGetterTestCases {}

mixin UndefinedGetterTestCases on PubPackageResolutionTest {
  test_compoundAssignment_hasSetter_instance() async {
    await assertErrorsInCode('''
class C {
  set foo(int _) {}
}

f(C c) {
  c.foo += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 46, 3),
    ]);
  }

  test_compoundAssignment_hasSetter_static() async {
    await assertErrorsInCode('''
class C {
  static set foo(int _) {}
}

f() {
  C.foo += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 50, 3),
    ]);
  }

  test_emptyName() async {
    await assertErrorsInCode('''
class A {
}
main() {
  print(A().);
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 33, 1),
    ]);
  }

  test_extension_instance_extendedHasSetter_extensionHasGetter() async {
    await assertErrorsInCode('''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;

  f() {
    this.foo;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 95, 3),
    ]);
  }

  test_extension_instance_undefined_hasSetter() async {
    await assertErrorsInCode('''
extension E on int {
  void set foo(int _) {}
}
f() {
  0.foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 58, 3),
    ]);
  }

  test_extension_instance_withInference() async {
    await assertErrorsInCode(r'''
extension E on int {}
var a = 3.v;
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 32, 1),
    ]);
  }

  test_extension_instance_withoutInference() async {
    await assertErrorsInCode(r'''
class C {}

extension E on C {}

f(C c) {
  c.a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 46, 1),
    ]);
  }

  test_extension_this_extendedHasSetter_extensionHasGetter() async {
    await assertErrorsInCode('''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;
}

f(C c) {
  c.foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 93, 3),
    ]);
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

  test_ifElement_inList_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return [if (x is String) x.length];
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 6),
    ]);
  }

  test_ifElement_inList_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return [if (x is String) x.length];
}
''');
  }

  test_ifElement_inMap_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return {if (x is String) x : x.length};
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 44, 6),
    ]);
  }

  test_ifElement_inMap_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return {if (x is String) x : x.length};
}
''');
  }

  test_ifElement_inSet_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return {if (x is String) x.length};
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 6),
    ]);
  }

  test_ifElement_inSet_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return {if (x is String) x.length};
}
''');
  }

  test_ifStatement_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  if (x is String) {
    x.length;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 38, 6),
    ]);
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
    await assertErrorsInCode(r'''
class T {}
f(T e) { return e.m; }
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 29, 1),
    ]);
  }

  test_instance_undefined_mixin() async {
    await assertErrorsInCode(r'''
mixin M {
  f() { return this.m; }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 30, 1),
    ]);
  }

  test_nullMember_undefined() async {
    await assertErrorsInCode(
        r'''
m() {
  Null _null;
  _null.foo;
}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.INVALID_USE_OF_NULL_VALUE, 22, 5),
        ], legacy: [
          error(CompileTimeErrorCode.UNDEFINED_GETTER, 28, 3),
        ]));
  }

  test_object_call() async {
    await assertErrorsInCode('''
f(Object o) {
  return o.call;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 25, 4),
    ]);
  }

  test_promotedTypeParameter_regress35305() async {
    await assertErrorsInCode(r'''
void f<X extends num, Y extends X>(Y y) {
  if (y is int) {
    y.isEven;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 66, 6),
    ]);
  }

  test_propertyAccess_functionClass_call() async {
    await assertNoErrorsInCode('''
void f(Function a) {
  return (a).call;
}
''');
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

  test_proxy_annotation_fakeProxy() async {
    await assertErrorsInCode(r'''
library L;
class Fake {
  const Fake();
}
const proxy = const Fake();
@proxy class PrefixProxy {}
main() {
  new PrefixProxy().foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 127, 3),
    ]);
  }

  test_static_conditionalAcces_defined() async {
    // The conditional access operator '?.' can be used to access static
    // fields.
    await assertNoErrorsInCode('''
class A {
  static var x;
}
var a = A?.x;
''');
  }

  test_static_definedInSuperclass() async {
    await assertErrorsInCode('''
class S {
  static int get g => 0;
}
class C extends S {}
f(var p) {
  f(C.g);
}''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 75, 1),
    ]);
  }

  test_static_undefined() async {
    await assertErrorsInCode('''
class C {}
f(var p) {
  f(C.m);
}''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 28, 1),
    ]);
  }

  test_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class T {
  static int get foo => 42;
}
main() {
  T..foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 54, 3),
    ]);
  }

  test_typeLiteral_conditionalAccess() async {
    // When applied to a type literal, the conditional access operator '?.'
    // cannot be used to access instance getters of Type.
    await assertErrorsInCode('''
class A {}
f() => A?.hashCode;
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 21, 8),
    ]);
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

@reflectiveTest
class UndefinedGetterWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin, UndefinedGetterTestCases {
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
}
