// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOverrideTest);
    defineReflectiveTests(InvalidOverrideWithNnbdTest);
  });
}

@reflectiveTest
class InvalidOverrideTest extends DriverResolutionTest {
  test_getter_returnType() async {
    await assertErrorsInCode('''
class A {
  int get g { return 0; }
}
class B extends A {
  String get g { return 'a'; }
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 71, 1),
    ]);
  }

  test_getter_returnType_implicit() async {
    await assertErrorsInCode('''
class A {
  String f;
}
class B extends A {
  int f;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 50, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 50, 1),
    ]);
  }

  test_getter_returnType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_11.dart
    await assertErrorsInCode('''
abstract class I {
  int get getter => null;
}
abstract class J {
  num get getter => null;
}
abstract class A implements I, J {}
class B extends A {
  String get getter => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 163, 6),
    ]);
  }

  test_getter_returnType_twoInterfaces_conflicting() async {
    await assertErrorsInCode('''
abstract class I<U> {
  U get g => null;
}
abstract class J<V> {
  V get g => null;
}
class B implements I<int>, J<String> {
  double get g => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 138, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 138, 1),
    ]);
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 52, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 72, 3),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 1),
    ]);
  }

  test_method_namedParamType() async {
    await assertErrorsInCode('''
class A {
  m({int a}) {}
}
class B implements A {
  m({String a}) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 53, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 51, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 48, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 147, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 147, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 124, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 140, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 140, 1),
    ]);
  }

  test_method_optionalParamType() async {
    await assertErrorsInCode('''
class A {
  m([int a]) {}
}
class B implements A {
  m([String a]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 53, 1),
    ]);
  }

  test_method_optionalParamType_twoInterfaces() async {
    await assertErrorsInCode('''
abstract class I {
  m([int n]);
}
abstract class J {
  m([num n]);
}
abstract class A implements I, J {}
class B extends A {
  m([String n]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 128, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 55, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 55, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 44, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 68, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 98, 1),
    ]);
  }

  test_method_returnType_mixin() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B extends Object with A {
  String m() { return 'a'; }
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 77, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 65, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 87, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 129, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 63, 1),
    ]);
  }

  test_mixin_field_type() async {
    await assertErrorsInCode(r'''
class A {
  String foo = '';
}

mixin M on A {
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 53, 3),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 53, 3),
    ]);
  }

  test_mixin_getter_type() async {
    await assertErrorsInCode(r'''
class A {
  String get foo => '';
}

mixin M on A {
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 62, 3),
    ]);
  }

  test_mixin_method_returnType() async {
    await assertErrorsInCode(r'''
class A {
  String foo() => '';
}

mixin M on A {
  int foo() => 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 56, 3),
    ]);
  }

  test_mixin_setter_type() async {
    await assertErrorsInCode(r'''
class A {
  set foo(String _) {}
}

mixin M on A {
  set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 57, 3),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 66, 1),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 173, 8),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 166, 8),
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
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 125, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 125, 1),
    ]);
  }
}

@reflectiveTest
class InvalidOverrideWithNnbdTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    )
    ..implicitCasts = false;

  @override
  bool get typeToStringWithNullability => true;

  test_method_parameter_functionTyped_optOut_extends_optIn() async {
    newFile('/test/lib/a.dart', content: r'''
abstract class A {
  A catchError(void Function(Object) a);
}
''');

    await assertNoErrorsInCode('''
// @dart=2.6
import 'a.dart';

class B implements A {
  A catchError(void Function(dynamic) a) => this;
}
''');
  }

  test_method_parameter_interfaceOptOut_concreteOptIn() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void foo(Object a) {}
}
''');

    await assertNoErrorsInCode('''
// @dart=2.6
import 'a.dart';

class B extends A {
  void foo(dynamic a);
}
''');
  }

  test_mixedInheritance_1() async {
    newFile('/test/lib/a.dart', content: r'''
class B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}
''');

    newFile('/test/lib/b.dart', content: r'''
// @dart = 2.7
import 'a.dart';

class C with B {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';
import 'b.dart';

class D extends C implements Bq {}
''');
  }

  test_mixedInheritance_2() async {
    newFile('/test/lib/a.dart', content: r'''
class B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}
''');

    newFile('/test/lib/b.dart', content: r'''
// @dart = 2.7
import 'a.dart';

class C extends B with Bq {}
''');

    await assertNoErrorsInCode(r'''
import 'b.dart';

class D extends C {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}
''');
  }

  test_viaLegacy_class() async {
    newFile('/test/lib/a.dart', content: r'''
class A1 {
  int m() => 0;
  int get g => 0;
  set s(int? _) {}
}

class A2 {
  int? m() => 0;
  int? get g => 0;
  set s(int _) {}
}
''');

    newFile('/test/lib/b.dart', content: r'''
// @dart=2.6
import 'a.dart';

class L extends A2 implements A1 {}
''');

    await assertNoErrorsInCode('''
import 'a.dart';
import 'b.dart';

class X1 extends L implements A1 {}
class X2 extends L implements A2 {}

class Y extends L {
  int? get g => 0;
  int? m() => 0;
  set s(int _) {}
}
''');
  }

  test_viaLegacy_mixin() async {
    newFile('/test/lib/a.dart', content: r'''
class A1 {
  int m() => 0;
  int get g => 0;
  set s(int? _) {}
}

mixin A2 {
  int? m() => 0;
  int? get g => 0;
  set s(int _) {}
}
''');

    newFile('/test/lib/b.dart', content: r'''
// @dart=2.6
import 'a.dart';

class L extends Object with A2 implements A1 {}
''');

    await assertNoErrorsInCode('''
import 'a.dart';
import 'b.dart';

class X1 extends L implements A1 {}
class X2 extends L implements A2 {}

class Y extends L {
  int? get g => 0;
  int? m() => 0;
  set s(int _) {}
}
''');
  }
}
