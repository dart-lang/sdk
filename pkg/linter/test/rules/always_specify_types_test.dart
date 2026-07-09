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
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
f() {
  ({/*[0*/final/*0]*/ p1, required /*[1*/final/*1]*/ p2}) {};
}
''');
  }

  test_closureParameter_named_ok() async {
    await assertNoDiagnostics(r'''
f() {
  ({int? p1, required int p2}) {};
}
''');
  }

  test_closureParameter_named_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  ({/*[0*/p1/*0]*/, /*[1*/required p2/*1]*/}) {};
}
''');
  }

  test_closureParameter_named_passed_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
m(void Function({int? p1, required int p2}) f) {}
f() {
  m(({/*[0*/final/*0]*/ p1, required /*[1*/final/*1]*/ p2}) {});
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
m(void Function({int? p1, required int p2}) f) {}
f() {
  m(({/*[0*/p1/*0]*/, /*[1*/required p2/*1]*/}) {});
}
''');
  }

  test_closureParameter_named_passed_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
m(void Function({int? p1, required int p2}) f) {}
f() {
  m(({/*[0*/var/*0]*/ p1, required /*[1*/var/*1]*/ p2}) {});
}
''');
  }

  test_closureParameter_named_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
f() {
  ({/*[0*/var/*0]*/ p1, required /*[1*/var/*1]*/ p2}) {};
}
''');
  }

  test_closureParameter_positional_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
f() {
  (/*[0*/final/*0]*/ p1, [/*[1*/final/*1]*/ p2]) {};
}
''');
  }

  test_closureParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
f() {
  (int p1, int p2, [int? p3]) {};
}
''');
  }

  test_closureParameter_positional_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  (/*[0*/p1/*0]*/, [/*[1*/p2/*1]*/]) {};
}
''');
  }

  test_closureParameter_positional_passed_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
m(void Function(int, [int?]) f) {}
f() {
  m((/*[0*/final/*0]*/ p1, [/*[1*/final/*1]*/ p2]) {});
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
m(void Function(int, [int?]) f) {}
f() {
  m((/*[0*/p1/*0]*/, [/*[1*/p2/*1]*/]) {});
}
''');
  }

  test_closureParameter_positional_passed_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
m(void Function(int, [int?]) f) {}
f() {
  m((/*[0*/var/*0]*/ p1, [/*[1*/var/*1]*/ p2]) {});
}
''');
  }

  test_closureParameter_positional_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
f() {
  (/*[0*/var/*0]*/ p1, [/*[1*/var/*1]*/ p2]) {};
}
''');
  }

  test_constructorParameter_named_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  C({/*[0*/final/*0]*/ p1, required /*[1*/final/*1]*/ p2});
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C {
  C({/*[0*/p1/*0]*/, /*[1*/required p2/*1]*/}) {}
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  C({/*[0*/var/*0]*/ p1, required /*[1*/var/*1]*/ p2});
}
''');
  }

  test_constructorParameter_positional_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  C(/*[0*/final/*0]*/ p1, [/*[1*/final/*1]*/ p2]);
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C {
  C(/*[0*/p1/*0]*/, [/*[1*/p2/*1]*/]);
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  C(/*[0*/var/*0]*/ p1, [/*[1*/var/*1]*/ p2]);
}
''');
  }

  test_constructorTearoff_keptGeneric() async {
    await assertNoDiagnostics(r'''
void f() {
  List<E> Function<E>(int, E) filledList = List.filled;
}
''');
  }

  test_constructorTearoff_typeArgument() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  List<[!List!]>.filled;
}
''');
  }

  test_declaredVariable_genericTypeAlias() async {
    await assertDiagnosticsFromMarkup(r'''
typedef StringMap<V> = Map<String, V>;
[!StringMap?!] x;
''');
  }

  test_declaredVariable_genericTypeAlias_inferredTypeArguments() async {
    await assertDiagnosticsFromMarkup(r'''
typedef StringMap<V> = Map<String, V>;
[!StringMap!] x = StringMap<String>();
''');
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
    await assertDiagnosticsFromMarkup(r'''
extension type E([!i!]) {}
''');
  }

  test_extensionType_typeArgs_annotation() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E<T>(int i) { }

void f() {
  [!E!] e = throw '';
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
extension type E<T>(int i) { }

f() {
  return [!E!](1);
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!var!] x;
}
''');
  }

  test_forLoopVariableDeclaration_var() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for ([!var!] i = 0; i < 10; ++i) {
    print(i);
  }
}
''');
  }

  test_function_optionalTypeArgs() async {
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

  test_function_optionalTypeArgs_withBound() async {
    // https://github.com/dart-lang/linter/issues/851
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f() {
  g<Object>();
  g();
}

@optionalTypeArgs
void g<T extends Object>() {}
''');
  }

  test_function_parameterType_explicit() async {
    await assertNoDiagnostics(r'''
void f(int x) {}
''');
  }

  test_function_parameterType_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
void f([!final!] x) {}
''');
  }

  test_function_parameterType_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
void f([!p!]) {}
''');
  }

  test_function_parameterType_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
void f([!var!] p) {}
''');
  }

  test_functionExpression_parameterType_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<String> p) {
  p.forEach(([!s!]) => print(s));
}
''');
  }

  test_functionExpression_parameterType_omitted_wildcard() async {
    await assertNoDiagnostics(r'''
void f(List<String> p) {
  p.forEach((_) {});
}
''');
  }

  test_functionExpression_parameterType_untyped() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<String> p) {
  p.forEach(([!s!]) => print(s));
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
typedef StringMap<V> = Map<String, V>;
StringMap<String> x = [!StringMap!]();
''');
  }

  test_instanceField_final() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!final!] f = 0;
}
''');
  }

  test_instanceField_final_overridden() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class I {
  int get f;
}
class C implements I {
  [!final!] f = 0;
}
''');
  }

  test_instanceField_var_initialized() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!var!] f = 0;
}
''');
  }

  test_instanceField_var_overridden() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class I {
  abstract int f;
}
class C implements I {
  [!var!] f = 0;
}
''');
  }

  test_instanceField_var_uninitialized() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!var!] x;
}
''');
  }

  test_instanceMethodParameter_named_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  m({/*[0*/final/*0]*/ p1, required /*[1*/final/*1]*/ p2}) {}
}
''');
  }

  test_instanceMethodParameter_named_ok() async {
    await assertNoDiagnostics(r'''
class C {
  m({int? p1, required int p2}) {}
}
''');
  }

  test_instanceMethodParameter_named_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  m({/*[0*/p1/*0]*/, /*[1*/required p2/*1]*/}) {}
}
''');
  }

  test_instanceMethodParameter_named_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  m({/*[0*/var/*0]*/ p1, required /*[1*/var/*1]*/ p2}) {}
}
''');
  }

  test_instanceMethodParameter_positional_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  m(/*[0*/final/*0]*/ p1, [/*[1*/final/*1]*/ p2]) {}
}
''');
  }

  test_instanceMethodParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
class C {
  m(int p1, int p2, [int? p3]) {}
}
''');
  }

  test_instanceMethodParameter_positional_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  m(/*[0*/p1/*0]*/, [/*[1*/p2/*1]*/]) {}
}
''');
  }

  test_instanceMethodParameter_positional_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  m(/*[0*/var/*0]*/ p1, [/*[1*/var/*1]*/ p2]) {}
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C<T> { }

void f() {
  [!C!] c = throw '';
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C<T> { }

f() {
  return [!C!]();
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
f() {
  return /*[0*/[/*0]*/1];
}
''');
  }

  test_listLiteral_inferredTypeArgument() async {
    await assertDiagnosticsFromMarkup(r'''
List<String> x = /*[0*/[/*0]*/];
''');
  }

  test_listLiteral_ok() async {
    await assertNoDiagnostics(r'''
f() {
  return <int>[1];
}
''');
  }

  test_listPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  var [[!a!]] = <int>[1];
}
''');
  }

  test_listPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var [int a] = <int>[1];
}
''');
  }

  test_localFunctionParameter_named_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
f() {
  m({/*[0*/final/*0]*/ p1, required /*[1*/final/*1]*/ p2}) {}
  m(p1: 0, p2: 0);
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
f() {
  m({/*[0*/p1/*0]*/, /*[1*/required p2/*1]*/}) {}
  m(p1: 0, p2: 0);
}
''');
  }

  test_localFunctionParameter_named_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
f() {
  m({/*[0*/var/*0]*/ p1, required /*[1*/var/*1]*/ p2}) {}
  m(p1: 0, p2: 0);
}
''');
  }

  test_localFunctionParameter_positional_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
f() {
  m(/*[0*/final/*0]*/ p1, [/*[1*/final/*1]*/ p2]) {}
  m(0, 0);
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
f() {
  m(/*[0*/p1/*0]*/, [/*[1*/p2/*1]*/]) {}
  m(0, 0);
}
''');
  }

  test_localFunctionParameter_positional_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
f() {
  m(/*[0*/var/*0]*/ p1, [/*[1*/var/*1]*/ p2]) {}
  m(0, 0);
}
''');
  }

  test_localVariable_const() async {
    await assertDiagnosticsFromMarkup(r'''
m() {
  [!const!] f = 0;
}
''');
  }

  test_localVariable_final() async {
    await assertDiagnosticsFromMarkup(r'''
m() {
  [!final!] f = 0;
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
m() {
  [!var!] f = 0;
}
''');
  }

  test_localVariableDeclaration_var() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!var!] x = '';
}
''');
  }

  test_localVariableDeclaration_var_multiple() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!var!] x = '', y = 1.2;
}
''');
  }

  test_mapLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  return [!{!]1: ''};
}
''');
  }

  test_mapLiteral_empty() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  return [!{!]};
}
''');
  }

  test_mapLiteral_empty_ok() async {
    await assertNoDiagnostics(r'''
f() {
  return <int, String>{};
}
''');
  }

  test_mapLiteral_inferredTypeArguments() async {
    await assertDiagnosticsFromMarkup(r'''
Map<String, String> x = [!{!]};
''');
  }

  test_mapLiteral_ok() async {
    await assertNoDiagnostics(r'''
f() {
  return <int, String>{1: ''};
}
''');
  }

  test_mapPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  var {'a': [!a!]} = <String, int>{'a': 1};
}
''');
  }

  test_mapPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var {'a': int a} = <String, int>{'a': 1};
}
''');
  }

  test_objectPattern_switch_final() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && [!final!] b):
  }
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && [!var!] b):
  }
}
''');
  }

  test_primaryConstructor_declaringParameter_final() async {
    await assertDiagnosticsFromMarkup(r'''
class C([!final!] x);
''');
  }

  test_primaryConstructor_declaringParameter_var() async {
    await assertDiagnosticsFromMarkup(r'''
class C([!var!] x);
''');
  }

  test_primaryConstructor_named_primary() async {
    await assertDiagnosticsFromMarkup(r'''
class C.named([!x!]);
''');
  }

  test_primaryConstructor_ok() async {
    await assertNoDiagnostics(r'''
class C(int x, final int y);
''');
  }

  test_primaryConstructor_parameter_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
class C([!x!]);
''');
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
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch ((1, 2)) {
    case (/*[0*/final/*0]*/ a, /*[1*/var/*1]*/ b):
  }
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
f() {
  return [!{!]1};
}
''');
  }

  test_setLiteral_inferredTypeArgument() async {
    await assertDiagnosticsFromMarkup(r'''
Set<String> set = [!{!]};
''');
  }

  test_setLiteral_ok() async {
    await assertNoDiagnostics(r'''
f() {
  return <int>{1};
}
''');
  }

  test_staticField_const() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static [!const!] f = 0;
}
''');
  }

  test_staticField_final() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static [!final!] f = 0;
}
''');
  }

  test_staticField_var() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static [!var!] f = 0;
}
''');
  }

  test_staticMethodParameter_named_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  static m({/*[0*/final/*0]*/ p1, required /*[1*/final/*1]*/ p2}) {}
}
''');
  }

  test_staticMethodParameter_named_ok() async {
    await assertNoDiagnostics(r'''
class C {
  static m({int? p1, required int p2}) {}
}
''');
  }

  test_staticMethodParameter_named_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static m({/*[0*/p1/*0]*/, /*[1*/required p2/*1]*/}) {}
}
''');
  }

  test_staticMethodParameter_named_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  static m({/*[0*/var/*0]*/ p1, required /*[1*/var/*1]*/ p2}) {}
}
''');
  }

  test_staticMethodParameter_positional_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  static m(/*[0*/final/*0]*/ p1, [/*[1*/final/*1]*/ p2]) {}
}
''');
  }

  test_staticMethodParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
class C {
  static m(int p1, int p2, [int? p3]) {}
}
''');
  }

  test_staticMethodParameter_positional_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static m(/*[0*/p1/*0]*/, [/*[1*/p2/*1]*/]) {}
}
''');
  }

  test_staticMethodParameter_positional_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class C {
  static m(/*[0*/var/*0]*/ p1, [/*[1*/var/*1]*/ p2]) {}
}
''');
  }

  test_topLevelField_const() async {
    await assertDiagnosticsFromMarkup(r'''
[!const!] f = 0;
''');
  }

  test_topLevelField_final() async {
    await assertDiagnosticsFromMarkup(r'''
[!final!] f = 0;
''');
  }

  test_topLevelField_ok() async {
    await assertNoDiagnostics(r'''
int f1 = 0;
final int f2 = 0;
const int f3 = 0;
''');
  }

  test_topLevelField_var() async {
    await assertDiagnosticsFromMarkup(r'''
[!var!] f = 0;
''');
  }

  test_topLevelParameter_named_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
m({/*[0*/final/*0]*/ p1, required /*[1*/final/*1]*/ p2}) {}
''');
  }

  test_topLevelParameter_named_ok() async {
    await assertNoDiagnostics(r'''
m({int? p1, required int p2}) {}
''');
  }

  test_topLevelParameter_named_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
m({/*[0*/p1/*0]*/, /*[1*/required p2/*1]*/}) {}
''');
  }

  test_topLevelParameter_named_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
m({/*[0*/var/*0]*/ p1, required /*[1*/var/*1]*/ p2}) {}
''');
  }

  test_topLevelParameter_positional_final() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
m(/*[0*/final/*0]*/ p1, [/*[1*/final/*1]*/ p2]) {}
''');
  }

  test_topLevelParameter_positional_ok() async {
    await assertNoDiagnostics(r'''
m(int p1, int p2, [int? p3]) {}
''');
  }

  test_topLevelParameter_positional_omitted() async {
    await assertDiagnosticsFromMarkup(r'''
m(/*[0*/p1/*0]*/, [/*[1*/p2/*1]*/]) {}
''');
  }

  test_topLevelParameter_positional_var() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
m(/*[0*/var/*0]*/ p1, [/*[1*/var/*1]*/ p2]) {}
''');
  }

  test_topLevelVariableDeclaration_explicitType() async {
    await assertNoDiagnostics(r'''
final int x = 3;
''');
  }

  test_topLevelVariableDeclaration_implicitTypeArgument() async {
    await assertDiagnosticsFromMarkup(r'''
[!List?!] x;
''');
  }

  test_topLevelVariableDeclaration_missingType_const() async {
    await assertDiagnosticsFromMarkup(r'''
[!const!] x = 2;
''');
  }

  test_topLevelVariableDeclaration_missingType_final() async {
    await assertDiagnosticsFromMarkup(r'''
[!final!] x = 1;
''');
  }

  test_topLevelVariableDeclaration_missingType_final_multiple() async {
    await assertDiagnosticsFromMarkup(r'''
[!final!] x = 1, y = '', z = 1.2;
''');
  }

  test_topLevelVariableDeclaration_missingType_multiple() async {
    await assertDiagnosticsFromMarkup(r'''
[!var!] x = '', y = '';
''');
  }

  test_topLevelVariableDeclaration_typeArgument_implicitTypeArgument() async {
    await assertDiagnosticsFromMarkup(r'''
List<[!List!]>? x;
''');
  }

  test_topLevelVariableDeclaration_var() async {
    await assertDiagnosticsFromMarkup(r'''
[!var!] x;
''');
  }

  test_typedef_aliased_typeArgument_withImplicitTypeArgument() async {
    await assertDiagnosticsFromMarkup(r'''
typedef StringMap<V> = Map<String, V>;
typedef MapList = List<[!StringMap!]>;
''');
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
    await assertDiagnosticsFromMarkup(r'''
typedef RawList = [!List!];
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C<T> { }
typedef F<T> = C<T>;

void f() {
  [!F!] f = throw '';
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C<T> { }
typedef F<T> = C<T>;

f() {
  return [!F!]();
}
''');
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
