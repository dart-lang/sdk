// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOverrideTest);
  });
}

@reflectiveTest
class InvalidOverrideTest extends PubPackageResolutionTest {
  test_abstract_field_covariant_inheritance() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract covariant num x;
}
abstract class B implements A {
  void set x(Object value); // Implicitly covariant
}
abstract class C implements B {
  int get x;
  void set x(int value); // Ok because covariant
}
''');
  }

  test_external_field_covariant_inheritance() async {
    await assertNoErrorsInCode('''
abstract class A {
  external covariant num x;
}
abstract class B implements A {
  void set x(Object value); // Implicitly covariant
}
abstract class C implements B {
  int get x;
  void set x(int value); // Ok because covariant
}
''');
  }

  test_getter_overrides_abstract_field_covariant_invalid() async {
    await assertErrorsInCode('''
abstract class A {
  abstract covariant int x;
}
abstract class B implements A {
  num get x;
  void set x(num value);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 91, 1,
          contextMessages: [message(testFile, 44, 1)]),
    ]);
  }

  test_getter_overrides_abstract_field_covariant_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract covariant num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_abstract_field_final_invalid() async {
    await assertErrorsInCode('''
abstract class A {
  abstract final int x;
}
abstract class B implements A {
  num get x;
  void set x(num value);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 87, 1,
          contextMessages: [message(testFile, 40, 1)]),
    ]);
  }

  test_getter_overrides_abstract_field_final_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_abstract_field_invalid() async {
    await assertErrorsInCode('''
abstract class A {
  abstract int x;
}
abstract class B implements A {
  num get x;
  void set x(num value);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 81, 1,
          contextMessages: [message(testFile, 34, 1)]),
    ]);
  }

  test_getter_overrides_abstract_field_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_external_field_covariant_invalid() async {
    await assertErrorsInCode('''
class A {
  external covariant int x;
}
abstract class B implements A {
  num get x;
  void set x(num value);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 82, 1,
          contextMessages: [message(testFile, 35, 1)]),
    ]);
  }

  test_getter_overrides_external_field_covariant_valid() async {
    await assertNoErrorsInCode('''
class A {
  external covariant num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_external_field_final_invalid() async {
    await assertErrorsInCode('''
class A {
  external final int x;
}
abstract class B implements A {
  num get x;
  void set x(num value);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 78, 1,
          contextMessages: [message(testFile, 31, 1)]),
    ]);
  }

  test_getter_overrides_external_field_final_valid() async {
    await assertNoErrorsInCode('''
class A {
  external final num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_overrides_external_field_invalid() async {
    await assertErrorsInCode('''
class A {
  external int x;
}
abstract class B implements A {
  num get x;
  void set x(num value);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 72, 1,
          contextMessages: [message(testFile, 25, 1)]),
    ]);
  }

  test_getter_overrides_external_field_valid() async {
    await assertNoErrorsInCode('''
class A {
  external num x;
}
abstract class B implements A {
  int get x;
}
''');
  }

  test_getter_returnType() async {
    await assertErrorsInCode('''
class A {
  int get g { return 0; }
}
class B extends A {
  String get g { return 'a'; }
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 71, 1,
          contextMessages: [message(testFile, 20, 1)]),
    ]);
  }

  test_getter_returnType_implicit() async {
    await assertErrorsInCode('''
class A {
  String? f;
}
class B extends A {
  int? f;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 52, 1,
          contextMessages: [message(testFile, 20, 1)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 52, 1,
          contextMessages: [message(testFile, 20, 1)]),
    ]);
  }

  test_getter_returnType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_11.dart
    await assertErrorsInCode('''
abstract class I {
  int get getter => 0;
}
abstract class J {
  num get getter => 0;
}
abstract class A implements I, J {}
class B extends A {
  String get getter => '';
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 157, 6,
          contextMessages: [message(testFile, 29, 6)]),
    ]);
  }

  test_getter_returnType_twoInterfaces_conflicting() async {
    await assertErrorsInCode('''
abstract class I<U> {
  U get g => throw 0;
}
abstract class J<V> {
  V get g => throw 0;
}
class B implements I<int>, J<String> {
  double get g => throw 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 144, 1,
          contextMessages: [message(testFile, 30, 1)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 144, 1,
          contextMessages: [message(testFile, 76, 1)]),
    ]);
  }

  test_issue48468() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo<T extends R, R>();
}

class B implements A {
  void foo<T extends R, R>() {}
}
''');
  }

  test_method_abstractOverridesConcrete() async {
    await assertErrorsInCode('''
class A	{
  int add(int a, int b) => a + b;
}
class B	extends A {
  int add();
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 52, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 72, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_method_abstractOverridesConcreteInMixin() async {
    await assertErrorsInCode('''
mixin M {
  int add(int a, int b) => a + b;
}
class A with M {
  int add();
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 52, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 69, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_method_abstractOverridesConcreteViaMixin() async {
    await assertErrorsInCode('''
class A {
  int add(int a, int b) => a + b;
}
mixin M {
  int add();
}
class B	extends A with M {}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 77, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 94, 1,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_method_covariant_1() async {
    await assertNoErrorsInCode(r'''
abstract class A<T> {
  A<U> foo<U>(covariant A<Map<T, U>> a);
}

abstract class B<U, T> extends A<T> {
  B<U, V> foo<V>(B<U, Map<T, V>> a);
}
''');
  }

  test_method_covariant_2() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  R foo<R>(VA<R> v);
}

abstract class B implements A {
  R foo<R>(covariant VB<R> v);
}

abstract class VA<T> {}

abstract class VB<T> implements VA<T> {}
''');
  }

  test_method_covariant_3() async {
    await assertErrorsInCode(r'''
class A {
  void foo(num a) {}
}

class B extends A {
  void foo(dynamic a) {}
}

class C extends B {
  void foo(covariant String a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 109, 3),
    ]);
  }

  test_method_named_fewerNamedParameters() async {
    await assertErrorsInCode('''
class A {
  m({a, b}) {}
}
class B extends A {
  m({a}) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_named_missingNamedParameter() async {
    await assertErrorsInCode('''
class A {
  m({a, b}) {}
}
class B extends A {
  m({a, c}) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_namedParamType() async {
    await assertErrorsInCode('''
class A {
  m({int? a}) {}
}
class B implements A {
  m({String? a}) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 54, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_normalParamType_interface() async {
    await assertErrorsInCode('''
class A {
  m(int a) {}
}
class B implements A {
  m(String a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 51, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_normalParamType_superclass() async {
    await assertErrorsInCode('''
class A {
  m(int a) {}
}
class B extends A {
  m(String a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 48, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_normalParamType_superclass_interface() async {
    await assertErrorsInCode('''
abstract class I<U> {
  void m(U u) => null;
}
abstract class J<V> {
  void m(V v) => null;
}
class B extends I<int> implements J<String> {
  void m(double d) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 147, 1,
          contextMessages: [message(testFile, 76, 1)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 147, 1,
          contextMessages: [message(testFile, 29, 1)]),
    ]);
  }

  test_method_normalParamType_twoInterfaces() async {
    await assertErrorsInCode('''
abstract class I {
  m(int n);
}
abstract class J {
  m(num n);
}
abstract class A implements I, J {}
class B extends A {
  m(String n) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 124, 1,
          contextMessages: [message(testFile, 54, 1)]),
    ]);
  }

  test_method_normalParamType_twoInterfaces_conflicting() async {
    // language/override_inheritance_generic_test/08
    await assertErrorsInCode('''
abstract class I<U> {
  void m(U u) => null;
}
abstract class J<V> {
  void m(V v) => null;
}
class B implements I<int>, J<String> {
  void m(double d) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 140, 1,
          contextMessages: [message(testFile, 29, 1)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 140, 1,
          contextMessages: [message(testFile, 76, 1)]),
    ]);
  }

  test_method_optionalParamType() async {
    await assertErrorsInCode('''
class A {
  m([int? a]) {}
}
class B implements A {
  m([String? a]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 54, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_optionalParamType_twoInterfaces() async {
    await assertErrorsInCode('''
abstract class I {
  m([int? n]);
}
abstract class J {
  m([num? n]);
}
abstract class A implements I, J {}
class B extends A {
  m([String? n]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 130, 1,
          contextMessages: [message(testFile, 57, 1)]),
    ]);
  }

  test_method_positional_optional() async {
    await assertErrorsInCode('''
class A {
  m([a, b]) {}
}
class B extends A {
  m([a]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_positional_optionalAndRequired() async {
    await assertErrorsInCode('''
class A {
  m(a, b, [c, d]) {}
}
class B extends A {
  m(a, b, [c]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 55, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_positional_optionalAndRequired2() async {
    await assertErrorsInCode('''
class A {
  m(a, b, [c, d]) {}
}
class B extends A {
  m(a, [c, d]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 55, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_required() async {
    await assertErrorsInCode('''
class A {
  m(a) {}
}
class B extends A {
  m(a, b) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 44, 1,
          contextMessages: [message(testFile, 12, 1)]),
    ]);
  }

  test_method_returnType_interface() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B implements A {
  String m() { return 'a'; }
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 68, 1,
          contextMessages: [message(testFile, 16, 1)]),
    ]);
  }

  test_method_returnType_interface_fromAugmentation() async {
    await assertErrorsInCode('''
class A {
  int foo() => 0;
}

class B {
  String foo() => '';
}

augment class B implements A {}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 50, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_method_returnType_interface_grandparent() async {
    await assertErrorsInCode('''
abstract class A {
  int m();
}
abstract class B implements A {
}
class C implements B {
  String m() { return 'a'; }
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 98, 1,
          contextMessages: [message(testFile, 25, 1)]),
    ]);
  }

  test_method_returnType_mixin() async {
    await assertErrorsInCode('''
mixin class A {
  int m() { return 0; }
}
class B extends Object with A {
  String m() { return 'a'; }
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 83, 1,
          contextMessages: [message(testFile, 22, 1)]),
    ]);
  }

  test_method_returnType_superclass() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B extends A {
  String m() { return 'a'; }
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 65, 1,
          contextMessages: [message(testFile, 16, 1)]),
    ]);
  }

  test_method_returnType_superclass_fromAugmentation() async {
    await assertErrorsInCode('''
class A {
  int foo() => 0;
}

class B {
  String foo() => '';
}

augment class B extends A {}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 50, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_method_returnType_superclass_grandparent() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B extends A {
}
class C extends B {
  String m() { return 'a'; }
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 87, 1,
          contextMessages: [message(testFile, 16, 1)]),
    ]);
  }

  test_method_returnType_twoInterfaces() async {
    await assertErrorsInCode('''
abstract class I {
  int m();
}
abstract class J {
  num m();
}
abstract class A implements I, J {}
class B extends A {
  String m() => '';
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 129, 1,
          contextMessages: [message(testFile, 25, 1)]),
    ]);
  }

  test_method_returnType_void() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B extends A {
  void m() {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 63, 1,
          contextMessages: [message(testFile, 16, 1)]),
    ]);
  }

  test_mixin_field_type_on() async {
    await assertErrorsInCode(r'''
class A {
  String foo = '';
}

mixin M on A {
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 53, 3,
          contextMessages: [message(testFile, 19, 3)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 53, 3,
          contextMessages: [message(testFile, 19, 3)]),
    ]);
  }

  test_mixin_getter_type_on() async {
    await assertErrorsInCode(r'''
class A {
  String get foo => '';
}

mixin M on A {
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 62, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_mixin_method_returnType_on() async {
    await assertErrorsInCode(r'''
class A {
  String foo() => '';
}

mixin M on A {
  int foo() => 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 56, 3,
          contextMessages: [message(testFile, 19, 3)]),
    ]);
  }

  test_mixin_method_returnType_on_fromAugmentation() async {
    await assertErrorsInCode(r'''
class A {
  int foo() => 0;
}

mixin M {
  String foo() => '';
}

augment mixin M on A {}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 50, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_mixin_setter_type_on() async {
    await assertErrorsInCode(r'''
class A {
  set foo(String _) {}
}

mixin M on A {
  set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 57, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_setter_normalParamType() async {
    await assertErrorsInCode('''
class A {
  void set s(int v) {}
}
class B extends A {
  void set s(String v) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 66, 1,
          contextMessages: [message(testFile, 21, 1)]),
    ]);
  }

  test_setter_normalParamType_superclass_interface() async {
    await assertErrorsInCode('''
abstract class I {
  set setter14(int _) => null;
}
abstract class J {
  set setter14(num _) => null;
}
abstract class A extends I implements J {}
class B extends A {
  set setter14(String _) => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 173, 8,
          contextMessages: [message(testFile, 77, 8)]),
    ]);
  }

  test_setter_normalParamType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_34.dart
    await assertErrorsInCode('''
abstract class I {
  set setter14(int _) => null;
}
abstract class J {
  set setter14(num _) => null;
}
abstract class A implements I, J {}
class B extends A {
  set setter14(String _) => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 166, 8,
          contextMessages: [message(testFile, 77, 8)]),
    ]);
  }

  test_setter_normalParamType_twoInterfaces_conflicting() async {
    await assertErrorsInCode('''
abstract class I<U> {
  set s(U u) {}
}
abstract class J<V> {
  set s(V v) {}
}
class B implements I<int>, J<String> {
  set s(double d) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 125, 1,
          contextMessages: [message(testFile, 28, 1)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 125, 1,
          contextMessages: [message(testFile, 68, 1)]),
    ]);
  }

  test_setter_overrides_abstract_field_covariant_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract covariant num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''');
  }

  test_setter_overrides_abstract_field_final_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''');
  }

  test_setter_overrides_abstract_field_invalid() async {
    await assertErrorsInCode('''
abstract class A {
  abstract num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 95, 1,
          contextMessages: [message(testFile, 34, 1)],
          messageContains: ["'B.x'"]),
    ]);
  }

  test_setter_overrides_abstract_field_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
}
abstract class B implements A {
  void set x(num value);
}
''');
  }

  test_setter_overrides_external_field_covariant_valid() async {
    await assertNoErrorsInCode('''
class A {
  external covariant num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''');
  }

  test_setter_overrides_external_field_final_valid() async {
    await assertNoErrorsInCode('''
class A {
  external final num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''');
  }

  test_setter_overrides_external_field_invalid() async {
    await assertErrorsInCode('''
class A {
  external num x;
}
abstract class B implements A {
  int get x;
  void set x(int value);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE_SETTER, 86, 1,
          contextMessages: [message(testFile, 25, 1)]),
    ]);
  }

  test_setter_overrides_external_field_valid() async {
    await assertNoErrorsInCode('''
class A {
  external int x;
}
abstract class B implements A {
  void set x(num value);
}
''');
  }
}
