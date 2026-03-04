// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AlwaysSpecifyTypesTest);
  });
}

@reflectiveTest
class AlwaysSpecifyTypesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.always_specify_types;

  test_0() async {
    await assertNoDiagnostics(r'''
/// https://github.com/dart-lang/linter/issues/3275
typedef Foo1 = Map<String, Object>;
final Foo1 foo = Foo1();
''');
  }

  test_34() async {
    // https://github.com/dart-lang/linter/issues/851
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f() {
  g<dynamic>();
  g();
}

@optionalTypeArgs
void g<T>() {}
''');
  }

  test_catchVariable_omitted() async {
    // https://codereview.chromium.org/1427223002/
    await assertNoDiagnostics(r'''
void f() {
  try {
  } catch (e) {
    print(e);
  }
}
''');
  }

  test_closureParameter_named_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
f() {
  ({final p1, required final p2}) {};
}
''',
      [lint(26, 5), lint(45, 5)],
    );
  }

  test_closureParameter_named_ok() async {
    await assertNoDiagnostics(r'''
f() {
  ({int? p1, required int p2}) {};
}
''');
  }

  test_closureParameter_named_omitted() async {
    await assertDiagnostics(
      r'''
f() {
  ({p1, required p2}) {};
}
''',
      [lint(10, 2), lint(14, 11)],
    );
  }

  test_closureParameter_named_passed_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
m(void Function({int? p1, required int p2}) f) {}
f() {
  m(({final p1, required final p2}) {});
}
''',
      [lint(78, 5), lint(97, 5)],
    );
  }

  test_closureParameter_named_passed_ok() async {
    await assertNoDiagnostics(r'''
m(void Function({int? p1, required int p2}) f) {}
f() {
  m(({int? p1, required int p2}) {});
}
''');
  }

  test_closureParameter_named_passed_omitted() async {
    await assertDiagnostics(
      r'''
m(void Function({int? p1, required int p2}) f) {}
f() {
  m(({p1, required p2}) {});
}
''',
      [lint(62, 2), lint(66, 11)],
    );
  }

  test_closureParameter_named_passed_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
m(void Function({int? p1, required int p2}) f) {}
f() {
  m(({var p1, required var p2}) {});
}
''',
      [lint(78, 3), lint(95, 3)],
    );
  }

  test_closureParameter_named_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
f() {
  ({var p1, required var p2}) {};
}
''',
      [lint(26, 3), lint(43, 3)],
    );
  }

  test_closureParameter_positional_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
f() {
  (final p1, [final p2]) {};
}
''',
      [lint(25, 5), lint(36, 5)],
    );
  }

  test_closureParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
f() {
  (int p1, int p2, [int? p3]) {};
}
''');
  }

  test_closureParameter_positional_omitted() async {
    await assertDiagnostics(
      r'''
f() {
  (p1, [p2]) {};
}
''',
      [lint(9, 2), lint(14, 2)],
    );
  }

  test_closureParameter_positional_passed_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
m(void Function(int, [int?]) f) {}
f() {
  m((final p1, [final p2]) {});
}
''',
      [lint(62, 5), lint(73, 5)],
    );
  }

  test_closureParameter_positional_passed_ok() async {
    await assertNoDiagnostics(r'''
m(void Function(int, int, [int?]) f) {}
f() {
  m((int p1, int p2, [int? p3]) {});
}
''');
  }

  test_closureParameter_positional_passed_omitted() async {
    await assertDiagnostics(
      r'''
m(void Function(int, [int?]) f) {}
f() {
  m((p1, [p2]) {});
}
''',
      [lint(46, 2), lint(51, 2)],
    );
  }

  test_closureParameter_positional_passed_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
m(void Function(int, [int?]) f) {}
f() {
  m((var p1, [var p2]) {});
}
''',
      [lint(62, 3), lint(71, 3)],
    );
  }

  test_closureParameter_positional_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
f() {
  (var p1, [var p2]) {};
}
''',
      [lint(25, 3), lint(34, 3)],
    );
  }

  test_constructorParameter_named_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  C({final p1, required final p2});
}
''',
      [lint(31, 5), lint(50, 5)],
    );
  }

  test_constructorParameter_named_initializingFormal() async {
    await assertNoDiagnostics(r'''
class C {
  int? p1;
  int p2;
  C({this.p1, required this.p2});
}
''');
  }

  test_constructorParameter_named_ok() async {
    await assertNoDiagnostics(r'''
class C {
  C({int? p1, required int p2});
}
''');
  }

  test_constructorParameter_named_omitted() async {
    await assertDiagnostics(
      r'''
class C {
  C({p1, required p2}) {}
}
''',
      [lint(15, 2), lint(19, 11)],
    );
  }

  test_constructorParameter_named_superParameter() async {
    await assertNoDiagnostics(r'''
class S {
  S({int? p1, required int p2});
}
class C extends S {
  C({super.p1, required super.p2});
}
''');
  }

  test_constructorParameter_named_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  C({var p1, required var p2});
}
''',
      [lint(31, 3), lint(48, 3)],
    );
  }

  test_constructorParameter_positional_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  C(final p1, [final p2]);
}
''',
      [lint(30, 5), lint(41, 5)],
    );
  }

  test_constructorParameter_positional_initializingFormal() async {
    await assertNoDiagnostics(r'''
class C {
  int p1;
  int? p2;
  C(this.p1, [this.p2]);
}
''');
  }

  test_constructorParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
class C {
  C(int p1, int p2, [int? p3]);
}
''');
  }

  test_constructorParameter_positional_omitted() async {
    await assertDiagnostics(
      r'''
class C {
  C(p1, [p2]);
}
''',
      [lint(14, 2), lint(19, 2)],
    );
  }

  test_constructorParameter_positional_superParameter() async {
    await assertNoDiagnostics(r'''
class S {
  S(int p1, [int? p2]);
}
class C extends S {
  C(super.p1, [super.p2]);
}
''');
  }

  test_constructorParameter_positional_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  C(var p1, [var p2]);
}
''',
      [lint(30, 3), lint(39, 3)],
    );
  }

  test_constructorTearoff_keptGeneric() async {
    await assertNoDiagnostics(r'''
void f() {
  List<E> Function<E>(int, E) filledList = List.filled;
}
''');
  }

  test_constructorTearoff_typeArgument() async {
    await assertDiagnostics(
      r'''
void f() {
  List<List>.filled;
}
''',
      [lint(18, 4)],
    );
  }

  test_declaredVariable_genericTypeAlias() async {
    await assertDiagnostics(
      r'''
typedef StringMap<V> = Map<String, V>;
StringMap? x;
''',
      [lint(39, 10)],
    );
  }

  test_declaredVariable_genericTypeAlias_inferredTypeArguments() async {
    await assertDiagnostics(
      r'''
typedef StringMap<V> = Map<String, V>;
StringMap x = StringMap<String>();
''',
      [lint(39, 9)],
    );
  }

  test_extensionType_optionalTypeArgs() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@optionalTypeArgs
extension type E<T>(int i) { }

void f() {
  E e = E(1);
}
''');
  }

  test_extensionType_primaryConstructor_omitted() async {
    await assertDiagnostics(
      r'''
extension type E(i) {}
''',
      [lint(17, 1)],
    );
  }

  test_extensionType_typeArgs_annotation() async {
    await assertDiagnostics(
      r'''
extension type E<T>(int i) { }

void f() {
  E e = throw '';
}
''',
      [lint(45, 1)],
    );
  }

  test_extensionType_typeArgs_annotation_ok() async {
    await assertNoDiagnostics(r'''
extension type E<T>(int i) { }

void f() {
  E<int> e = throw '';
}
''');
  }

  test_extensionType_typeArgs_new() async {
    await assertDiagnostics(
      r'''
extension type E<T>(int i) { }

f() {
  return E(1);
}
''',
      [lint(47, 1)],
    );
  }

  test_extensionType_typeArgs_new_ok() async {
    await assertNoDiagnostics(r'''
extension type E<T>(int i) { }

f() {
  return E<int>(1);
}
''');
  }

  test_field_var() async {
    await assertDiagnostics(
      r'''
class C {
  var x;
}
''',
      [lint(12, 3)],
    );
  }

  test_forLoopVariableDeclaration_var() async {
    await assertDiagnostics(
      r'''
void f() {
  for (var i = 0; i < 10; ++i) {
    print(i);
  }
}
''',
      [lint(18, 3)],
    );
  }

  test_function_parameterType_explicit() async {
    await assertNoDiagnostics(r'''
void f(int x) {}
''');
  }

  test_function_parameterType_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
void f(final x) {}
''',
      [lint(23, 5)],
    );
  }

  test_function_parameterType_omitted() async {
    await assertDiagnostics(
      r'''
void f(p) {}
''',
      [lint(7, 1)],
    );
  }

  test_function_parameterType_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
void f(var p) {}
''',
      [lint(23, 3)],
    );
  }

  test_functionExpression_parameterType_omitted() async {
    await assertDiagnostics(
      r'''
void f(List<String> p) {
  p.forEach((s) => print(s));
}
''',
      [lint(38, 1)],
    );
  }

  test_functionExpression_parameterType_omitted_wildcard() async {
    await assertNoDiagnostics(r'''
void f(List<String> p) {
  p.forEach((_) {});
}
''');
  }

  test_functionExpression_parameterType_untyped() async {
    await assertDiagnostics(
      r'''
void f(List<String> p) {
  p.forEach((s) => print(s));
}
''',
      [lint(38, 1)],
    );
  }

  test_genericFunctionTypedVariable_invocation_instantiated() async {
    await assertNoDiagnostics(r'''
void f() {
  List<E> Function<E>(int, E) filledList = List.filled;
  filledList<int>(3, 3);
}
''');
  }

  test_genericFunctionTypedVariable_invocation_uninstantiated() async {
    // See #2914.
    await assertNoDiagnostics(r'''
void f() {
  List<E> Function<E>(int, E) filledList = List.filled;
  filledList(3, 3);
}
''');
  }

  test_genericMethodCall_ok() async {
    // Missing type arguments in generic method calls are _not_ covered by this
    // lint.
    await assertNoDiagnostics(r'''
m<T>() {}
f() {
  m();
}
''');
  }

  test_instanceCreation_genericTypeAlias_implicitTypeArgument() async {
    await assertDiagnostics(
      r'''
typedef StringMap<V> = Map<String, V>;
StringMap<String> x = StringMap();
''',
      [lint(61, 9)],
    );
  }

  test_instanceField_final() async {
    await assertDiagnostics(
      r'''
class C {
  final f = 0;
}
''',
      [lint(12, 5)],
    );
  }

  test_instanceField_final_overridden() async {
    await assertDiagnostics(
      r'''
abstract class I {
  int get f;
}
class C implements I {
  final f = 0;
}
''',
      [lint(59, 5)],
    );
  }

  test_instanceField_var_initialized() async {
    await assertDiagnostics(
      r'''
class C {
  var f = 0;
}
''',
      [lint(12, 3)],
    );
  }

  test_instanceField_var_overridden() async {
    await assertDiagnostics(
      r'''
abstract class I {
  abstract int f;
}
class C implements I {
  var f = 0;
}
''',
      [lint(64, 3)],
    );
  }

  test_instanceField_var_uninitialized() async {
    await assertDiagnostics(
      r'''
class C {
  var x;
}
''',
      [lint(12, 3)],
    );
  }

  test_instanceMethodParameter_named_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  m({final p1, required final p2}) {}
}
''',
      [lint(31, 5), lint(50, 5)],
    );
  }

  test_instanceMethodParameter_named_ok() async {
    await assertNoDiagnostics(r'''
class C {
  m({int? p1, required int p2}) {}
}
''');
  }

  test_instanceMethodParameter_named_omitted() async {
    await assertDiagnostics(
      r'''
class C {
  m({p1, required p2}) {}
}
''',
      [lint(15, 2), lint(19, 11)],
    );
  }

  test_instanceMethodParameter_named_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  m({var p1, required var p2}) {}
}
''',
      [lint(31, 3), lint(48, 3)],
    );
  }

  test_instanceMethodParameter_positional_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  m(final p1, [final p2]) {}
}
''',
      [lint(30, 5), lint(41, 5)],
    );
  }

  test_instanceMethodParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
class C {
  m(int p1, int p2, [int? p3]) {}
}
''');
  }

  test_instanceMethodParameter_positional_omitted() async {
    await assertDiagnostics(
      r'''
class C {
  m(p1, [p2]) {}
}
''',
      [lint(14, 2), lint(19, 2)],
    );
  }

  test_instanceMethodParameter_positional_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  m(var p1, [var p2]) {}
}
''',
      [lint(30, 3), lint(39, 3)],
    );
  }

  test_instanceStaticField_ok() async {
    await assertNoDiagnostics(r'''
abstract class I {
  abstract int f6;
  int get f7;
}
class C implements I {
  int f1 = 0;
  final int f2 = 0;
  static int f3 = 0;
  static final int f4 = 0;
  static const int f5 = 0;
  int f6 = 0;
  final int f7 = 0;
}
''');
  }

  test_interfaceType_optionalTypeArgs() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@optionalTypeArgs
class C<T> { }

void f() {
  C c = C();
}
''');
  }

  test_interfaceType_typeArgs_annotation() async {
    await assertDiagnostics(
      r'''
class C<T> { }

void f() {
  C c = throw '';
}
''',
      [lint(29, 1)],
    );
  }

  test_interfaceType_typeArgs_annotation_ok() async {
    await assertNoDiagnostics(r'''
class C<T> { }

void f() {
  C<int> c = throw '';
}
''');
  }

  test_interfaceType_typeArgs_new() async {
    await assertDiagnostics(
      r'''
class C<T> { }

f() {
  return C();
}
''',
      [lint(31, 1)],
    );
  }

  test_interfaceType_typeArgs_new_ok() async {
    await assertNoDiagnostics(r'''
class C<T> { }

f() {
  return C<int>();
}
''');
  }

  test_isExpression_typeArgument_implicit() async {
    await assertNoDiagnostics(r'''
void f(Object p) {
  p is Map;
}
''');
  }

  test_listLiteral() async {
    await assertDiagnostics(
      r'''
f() {
  return [1];
}
''',
      [lint(15, 1)],
    );
  }

  test_listLiteral_inferredTypeArgument() async {
    await assertDiagnostics(
      r'''
List<String> x = [];
''',
      [lint(17, 1)],
    );
  }

  test_listLiteral_ok() async {
    await assertNoDiagnostics(r'''
f() {
  return <int>[1];
}
''');
  }

  test_listPattern_destructured() async {
    await assertDiagnostics(
      r'''
f() {
  var [a] = <int>[1];
}
''',
      [lint(13, 1)],
    );
  }

  test_listPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var [int a] = <int>[1];
}
''');
  }

  test_localFunctionParameter_named_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
f() {
  m({final p1, required final p2}) {}
  m(p1: 0, p2: 0);
}
''',
      [lint(27, 5), lint(46, 5)],
    );
  }

  test_localFunctionParameter_named_ok() async {
    await assertNoDiagnostics(r'''
f() {
  m({int? p1, required int p2}) {}
  m(p1: 0, p2: 0);
}
''');
  }

  test_localFunctionParameter_named_omitted() async {
    await assertDiagnostics(
      r'''
f() {
  m({p1, required p2}) {}
  m(p1: 0, p2: 0);
}
''',
      [lint(11, 2), lint(15, 11)],
    );
  }

  test_localFunctionParameter_named_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
f() {
  m({var p1, required var p2}) {}
  m(p1: 0, p2: 0);
}
''',
      [lint(27, 3), lint(44, 3)],
    );
  }

  test_localFunctionParameter_positional_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
f() {
  m(final p1, [final p2]) {}
  m(0, 0);
}
''',
      [lint(26, 5), lint(37, 5)],
    );
  }

  test_localFunctionParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
f() {
  m(int p1, int p2, [int? p3]) {}
  m(0, 0, 0);
}
''');
  }

  test_localFunctionParameter_positional_omitted() async {
    await assertDiagnostics(
      r'''
f() {
  m(p1, [p2]) {}
  m(0, 0);
}
''',
      [lint(10, 2), lint(15, 2)],
    );
  }

  test_localFunctionParameter_positional_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
f() {
  m(var p1, [var p2]) {}
  m(0, 0);
}
''',
      [lint(26, 3), lint(35, 3)],
    );
  }

  test_localVariable_const() async {
    await assertDiagnostics(
      r'''
m() {
  const f = 0;
}
''',
      [lint(8, 5)],
    );
  }

  test_localVariable_final() async {
    await assertDiagnostics(
      r'''
m() {
  final f = 0;
}
''',
      [lint(8, 5)],
    );
  }

  test_localVariable_ok() async {
    await assertNoDiagnostics(r'''
m() {
  int f1 = 0;
  final int f2 = 0;
  const int f3 = 0;
}
''');
  }

  test_localVariable_var() async {
    await assertDiagnostics(
      r'''
m() {
  var f = 0;
}
''',
      [lint(8, 3)],
    );
  }

  test_localVariableDeclaration_var() async {
    await assertDiagnostics(
      r'''
void f() {
  var x = '';
}
''',
      [lint(13, 3)],
    );
  }

  test_localVariableDeclaration_var_multiple() async {
    await assertDiagnostics(
      r'''
void f() {
  var x = '', y = 1.2;
}
''',
      [lint(13, 3)],
    );
  }

  test_mapLiteral() async {
    await assertDiagnostics(
      r'''
f() {
  return {1: ''};
}
''',
      [lint(15, 1)],
    );
  }

  test_mapLiteral_empty() async {
    await assertDiagnostics(
      r'''
f() {
  return {};
}
''',
      [lint(15, 1)],
    );
  }

  test_mapLiteral_empty_ok() async {
    await assertNoDiagnostics(r'''
f() {
  return <int, String>{};
}
''');
  }

  test_mapLiteral_inferredTypeArguments() async {
    await assertDiagnostics(
      r'''
Map<String, String> x = {};
''',
      [lint(24, 1)],
    );
  }

  test_mapLiteral_ok() async {
    await assertNoDiagnostics(r'''
f() {
  return <int, String>{1: ''};
}
''');
  }

  test_mapPattern_destructured() async {
    await assertDiagnostics(
      r'''
f() {
  var {'a': a} = <String, int>{'a': 1};
}
''',
      [lint(18, 1)],
    );
  }

  test_mapPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var {'a': int a} = <String, int>{'a': 1};
}
''');
  }

  test_objectPattern_switch_final() async {
    await assertDiagnostics(
      r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && final b):
  }
}
''',
      [lint(79, 5)],
    );
  }

  test_objectPattern_switch_ok() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && int b):
  }
}
''');
  }

  test_objectPattern_switch_var() async {
    await assertDiagnostics(
      r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && var b):
  }
}
''',
      [lint(79, 3)],
    );
  }

  test_primaryConstructor_declaringParameter_final() async {
    await assertDiagnostics(
      r'''
class C(final x);
''',
      [lint(8, 5)],
    );
  }

  test_primaryConstructor_declaringParameter_var() async {
    await assertDiagnostics(
      r'''
class C(var x);
''',
      [lint(8, 3)],
    );
  }

  test_primaryConstructor_named_primary() async {
    await assertDiagnostics(
      r'''
class C.named(x);
''',
      [lint(14, 1)],
    );
  }

  test_primaryConstructor_ok() async {
    await assertNoDiagnostics(r'''
class C(int x, final int y);
''');
  }

  test_primaryConstructor_parameter_omitted() async {
    await assertDiagnostics(
      r'''
class C(x);
''',
      [lint(8, 1)],
    );
  }

  test_primaryConstructor_superParameter() async {
    await assertNoDiagnostics(r'''
class A {
  A(int p1);
}
class B(super.p1) extends A;
''');
  }

  test_primaryConstructor_this_ok() async {
    await assertNoDiagnostics(r'''
class C(this.x) {
  int x;
}
''');
  }

  test_recordPattern_switch() async {
    await assertDiagnostics(
      r'''
f() {
  switch ((1, 2)) {
    case (final a, var b):
  }
}
''',
      [lint(36, 5), lint(45, 3)],
    );
  }

  test_recordPattern_switch_ok() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (int a, int b):
  }
}
''');
  }

  test_setLiteral() async {
    await assertDiagnostics(
      r'''
f() {
  return {1};
}
''',
      [lint(15, 1)],
    );
  }

  test_setLiteral_inferredTypeArgument() async {
    await assertDiagnostics(
      r'''
Set<String> set = {};
''',
      [lint(18, 1)],
    );
  }

  test_setLiteral_ok() async {
    await assertNoDiagnostics(r'''
f() {
  return <int>{1};
}
''');
  }

  test_staticField_const() async {
    await assertDiagnostics(
      r'''
class C {
  static const f = 0;
}
''',
      [lint(19, 5)],
    );
  }

  test_staticField_final() async {
    await assertDiagnostics(
      r'''
class C {
  static final f = 0;
}
''',
      [lint(19, 5)],
    );
  }

  test_staticField_var() async {
    await assertDiagnostics(
      r'''
class C {
  static var f = 0;
}
''',
      [lint(19, 3)],
    );
  }

  test_staticMethodParameter_named_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  static m({final p1, required final p2}) {}
}
''',
      [lint(38, 5), lint(57, 5)],
    );
  }

  test_staticMethodParameter_named_ok() async {
    await assertNoDiagnostics(r'''
class C {
  static m({int? p1, required int p2}) {}
}
''');
  }

  test_staticMethodParameter_named_omitted() async {
    await assertDiagnostics(
      r'''
class C {
  static m({p1, required p2}) {}
}
''',
      [lint(22, 2), lint(26, 11)],
    );
  }

  test_staticMethodParameter_named_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  static m({var p1, required var p2}) {}
}
''',
      [lint(38, 3), lint(55, 3)],
    );
  }

  test_staticMethodParameter_positional_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  static m(final p1, [final p2]) {}
}
''',
      [lint(37, 5), lint(48, 5)],
    );
  }

  test_staticMethodParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
class C {
  static m(int p1, int p2, [int? p3]) {}
}
''');
  }

  test_staticMethodParameter_positional_omitted() async {
    await assertDiagnostics(
      r'''
class C {
  static m(p1, [p2]) {}
}
''',
      [lint(21, 2), lint(26, 2)],
    );
  }

  test_staticMethodParameter_positional_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C {
  static m(var p1, [var p2]) {}
}
''',
      [lint(37, 3), lint(46, 3)],
    );
  }

  test_topLevelField_const() async {
    await assertDiagnostics(
      r'''
const f = 0;
''',
      [lint(0, 5)],
    );
  }

  test_topLevelField_final() async {
    await assertDiagnostics(
      r'''
final f = 0;
''',
      [lint(0, 5)],
    );
  }

  test_topLevelField_ok() async {
    await assertNoDiagnostics(r'''
int f1 = 0;
final int f2 = 0;
const int f3 = 0;
''');
  }

  test_topLevelField_var() async {
    await assertDiagnostics(
      r'''
var f = 0;
''',
      [lint(0, 3)],
    );
  }

  test_topLevelParameter_named_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
m({final p1, required final p2}) {}
''',
      [lint(19, 5), lint(38, 5)],
    );
  }

  test_topLevelParameter_named_ok() async {
    await assertNoDiagnostics(r'''
m({int? p1, required int p2}) {}
''');
  }

  test_topLevelParameter_named_omitted() async {
    await assertDiagnostics(
      r'''
m({p1, required p2}) {}
''',
      [lint(3, 2), lint(7, 11)],
    );
  }

  test_topLevelParameter_named_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
m({var p1, required var p2}) {}
''',
      [lint(19, 3), lint(36, 3)],
    );
  }

  test_topLevelParameter_positional_final() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
m(final p1, [final p2]) {}
''',
      [lint(18, 5), lint(29, 5)],
    );
  }

  test_topLevelParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
m(int p1, int p2, [int? p3]) {}
''');
  }

  test_topLevelParameter_positional_omitted() async {
    await assertDiagnostics(
      r'''
m(p1, [p2]) {}
''',
      [lint(2, 2), lint(7, 2)],
    );
  }

  test_topLevelParameter_positional_var() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
m(var p1, [var p2]) {}
''',
      [lint(18, 3), lint(27, 3)],
    );
  }

  test_topLevelVariableDeclaration_explicitType() async {
    await assertNoDiagnostics(r'''
final int x = 3;
''');
  }

  test_topLevelVariableDeclaration_implicitTypeArgument() async {
    await assertDiagnostics(
      r'''
List? x;
''',
      [lint(0, 5)],
    );
  }

  test_topLevelVariableDeclaration_missingType_const() async {
    await assertDiagnostics(
      r'''
const x = 2;
''',
      [lint(0, 5)],
    );
  }

  test_topLevelVariableDeclaration_missingType_final() async {
    await assertDiagnostics(
      r'''
final x = 1;
''',
      [lint(0, 5)],
    );
  }

  test_topLevelVariableDeclaration_missingType_final_multiple() async {
    await assertDiagnostics(
      r'''
final x = 1, y = '', z = 1.2;
''',
      [lint(0, 5)],
    );
  }

  test_topLevelVariableDeclaration_missingType_multiple() async {
    await assertDiagnostics(
      r'''
var x = '', y = '';
''',
      [lint(0, 3)],
    );
  }

  test_topLevelVariableDeclaration_typeArgument_implicitTypeArgument() async {
    await assertDiagnostics(
      r'''
List<List>? x;
''',
      [lint(5, 4)],
    );
  }

  test_topLevelVariableDeclaration_var() async {
    await assertDiagnostics(
      r'''
var x;
''',
      [lint(0, 3)],
    );
  }

  test_typedef_aliased_typeArgument_withImplicitTypeArgument() async {
    await assertDiagnostics(
      r'''
typedef StringMap<V> = Map<String, V>;
typedef MapList = List<StringMap>;
''',
      [lint(62, 9)],
    );
  }

  test_typedef_typeArgument_withExplicitTypeArgument() async {
    await assertNoDiagnostics(r'''
typedef JsonMap = Map<String, dynamic>;
''');
  }

  test_typedef_typeArgument_withExplicitTypeArgument_typeVariable() async {
    await assertNoDiagnostics(r'''
typedef StringMap<V> = Map<String, V>;
''');
  }

  test_typedef_withImplicitTypeArgument() async {
    await assertDiagnostics(
      r'''
typedef RawList = List;
''',
      [lint(18, 4)],
    );
  }

  test_typedefType_optionalTypeArgs() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

class C<T> { }

@optionalTypeArgs
typedef F<T> = C<T>;

void f() {
  F f = F();
}
''');
  }

  test_typedefType_typeArgs_annotation() async {
    await assertDiagnostics(
      r'''
class C<T> { }
typedef F<T> = C<T>;

void f() {
  F f = throw '';
}
''',
      [lint(50, 1)],
    );
  }

  test_typedefType_typeArgs_annotation_ok() async {
    await assertNoDiagnostics(r'''
class C<T> { }
typedef F<T> = C<T>;

void f() {
  F<int> f = throw '';
}
''');
  }

  test_typedefType_typeArgs_new() async {
    await assertDiagnostics(
      r'''
class C<T> { }
typedef F<T> = C<T>;

f() {
  return F();
}
''',
      [lint(52, 1)],
    );
  }

  test_typedefType_typeArgs_new_ok() async {
    await assertNoDiagnostics(r'''
class C<T> { }
typedef F<T> = C<T>;

f() {
  return F<int>();
}
''');
  }
}
