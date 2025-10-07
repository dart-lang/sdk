// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAnnotatingWithDynamicBulkTest);
    defineReflectiveTests(AvoidAnnotatingWithDynamicTest);
    defineReflectiveTests(AvoidReturnTypesOnSettersBulkTest);
    defineReflectiveTests(AvoidReturnTypesOnSettersTest);
    defineReflectiveTests(AvoidTypesOnClosureParametersBulkTest);
    defineReflectiveTests(AvoidTypesOnClosureParametersTest);
    defineReflectiveTests(
      SuperFormalParameterTypeIsNotSubtypeOfAssociatedBulkTest,
    );
    defineReflectiveTests(SuperFormalParameterTypeIsNotSubtypeOfAssociatedTest);
    defineReflectiveTests(TypeInitFormalsBulkTest);
    defineReflectiveTests(TypeInitFormalsTest);
    defineReflectiveTests(VarAndTypeTest);
    defineReflectiveTests(OmitLocaVariableTypesBulkTest);
    defineReflectiveTests(OmitLocaVariableTypesLintTest);
    defineReflectiveTests(OmitObviousLocalVariableTypesBulkTest);
    defineReflectiveTests(OmitObviousLocalVariableTypesLintTest);
    defineReflectiveTests(OmitObviousPropertyTypesLintBulkTest);
    defineReflectiveTests(OmitObviousPropertyTypesLintLintTest);
  });
}

@reflectiveTest
class AvoidAnnotatingWithDynamicBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_annotating_with_dynamic;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f(void foo(dynamic x)) {
  return null;
}

f2({dynamic defaultValue}) {
  return null;
}
''');
    await assertHasFix('''
f(void foo(x)) {
  return null;
}

f2({defaultValue}) {
  return null;
}
''');
  }
}

@reflectiveTest
class AvoidAnnotatingWithDynamicTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_annotating_with_dynamic;

  Future<void> test_insideFunctionTypedFormalParameter() async {
    await resolveTestCode('''
bad(void foo(dynamic x)) {
  return null;
}
''');
    await assertHasFix('''
bad(void foo(x)) {
  return null;
}
''');
  }

  Future<void> test_namedParameter() async {
    await resolveTestCode('''
bad({dynamic defaultValue}) {
  return null;
}
''');
    await assertHasFix('''
bad({defaultValue}) {
  return null;
}
''');
  }

  Future<void> test_normalParameter() async {
    await resolveTestCode('''
bad(dynamic defaultValue) {
  return null;
}
''');
    await assertHasFix('''
bad(defaultValue) {
  return null;
}
''');
  }

  Future<void> test_optionalParameter() async {
    await resolveTestCode('''
bad([dynamic defaultValue]) {
  return null;
}
''');
    await assertHasFix('''
bad([defaultValue]) {
  return null;
}
''');
  }
}

@reflectiveTest
class AvoidReturnTypesOnSettersBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_return_types_on_setters;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void set s(int s) {}
void set s2(int s2) {}
''');
    await assertHasFix('''
set s(int s) {}
set s2(int s2) {}
''');
  }
}

@reflectiveTest
class AvoidReturnTypesOnSettersTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_return_types_on_setters;

  Future<void> test_void() async {
    await resolveTestCode('''
void set speed2(int ms) {}
''');
    await assertHasFix('''
set speed2(int ms) {}
''');
  }
}

@reflectiveTest
class AvoidTypesOnClosureParametersBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_types_on_closure_parameters;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(List<Future<int>> list) {
  list.forEach((Future<int> defaultValue) {});
  list.forEach((Future<int> defaultValue) { defaultValue; });
}
''');
    await assertHasFix('''
void f(List<Future<int>> list) {
  list.forEach((defaultValue) {});
  list.forEach((defaultValue) { defaultValue; });
}
''');
  }
}

@reflectiveTest
class AvoidTypesOnClosureParametersTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_types_on_closure_parameters;

  Future<void> test_namedParameter() async {
    await resolveTestCode('''
void f(C c) {
  c.forEach(({Future<int>? p}) {});
}
class C {
  void forEach(void Function({Future<int>? p})) {}
}
''');
    await assertHasFix('''
void f(C c) {
  c.forEach(({p}) {});
}
class C {
  void forEach(void Function({Future<int>? p})) {}
}
''');
  }

  Future<void> test_normalParameter() async {
    await resolveTestCode('''
void f(C c) {
  c.forEach((Future<int>? p) {});
}
class C {
  void forEach(void Function(Future<int>? p)) {}
}
''');
    await assertHasFix('''
void f(C c) {
  c.forEach((p) {});
}
class C {
  void forEach(void Function(Future<int>? p)) {}
}
''');
  }

  Future<void> test_optionalParameter() async {
    await resolveTestCode('''
void f(C c) {
  c.forEach(([Future<int>? p]) {});
}
class C {
  void forEach(void Function([Future<int>? p])) {}
}
''');
    await assertHasFix('''
void f(C c) {
  c.forEach(([p]) {});
}
class C {
  void forEach(void Function([Future<int>? p])) {}
}
''');
  }
}

@reflectiveTest
class OmitLocaVariableTypesBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.omit_local_variable_types;

  Future<void> test_dotShorthand_list() async {
    await resolveTestCode('''
enum E { a, b }
E f() {
  E e = .a;
  List<E> listE = [.a];
  print(listE);
  E e2 = .b;
  print(e2);
  return e;
}
''');
    await assertHasFix('''
enum E { a, b }
E f() {
  var e = E.a;
  var listE = <E>[.a];
  print(listE);
  var e2 = E.b;
  print(e2);
  return e;
}
''');
  }

  Future<void> test_dotShorthand_multipleVariables() async {
    await resolveTestCode('''
enum E { a }
E f() {
  E e = .a;
  E e2 = .a;
  print(e2);
  return e;
}
''');
    await assertHasFix('''
enum E { a }
E f() {
  var e = E.a;
  var e2 = E.a;
  print(e2);
  return e;
}
''');
  }

  Future<void> test_singleFile() async {
    await resolveTestCode('''
List f() {
  const List<int> l = [];
  return l;
}

void f2(List<int> list) {
  for (final int i in list) {
    print(i);
  }
}
''');
    await assertHasFix('''
List f() {
  const l = <int>[];
  return l;
}

void f2(List<int> list) {
  for (final i in list) {
    print(i);
  }
}
''');
  }
}

@reflectiveTest
class OmitLocaVariableTypesLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeTypeAnnotation;

  @override
  String get lintCode => LintNames.omit_local_variable_types;

  Future<void> test_forEach_dotShorthands_functionType() async {
    await resolveTestCode('''
enum E { a, b, c }
void f() {
  for (E Function() e in [() => .a]) {
    print(e);
  }
}
''');
    await assertHasFix('''
enum E { a, b, c }
void f() {
  for (var e in <E Function()>[() => .a]) {
    print(e);
  }
}
''');
  }

  Future<void> test_forEach_dotShorthands_generic_nested() async {
    await resolveTestCode('''
enum E { a, b, c }

T ff<T>(T t, E e) => t;

void f() {
  for (E e in [ff(ff(.b, .b), .b)]) {
    print(e);
  }
}
''');
    await assertHasFix('''
enum E { a, b, c }

T ff<T>(T t, E e) => t;

void f() {
  for (var e in <E>[ff(ff(.b, .b), .b)]) {
    print(e);
  }
}
''');
  }

  Future<void>
  test_forEach_dotShorthands_generic_nested_explicitTypeArguments() async {
    await resolveTestCode('''
enum E { a, b, c }

T ff<T>(T t, E e) => t;

X fun<U, X>(U u, X x) => x;

void f() {
  for (int e in [fun(ff<E>(.a, E.a), 2)]) {
    print(e);
  }
}
''');
    await assertHasFix('''
enum E { a, b, c }

T ff<T>(T t, E e) => t;

X fun<U, X>(U u, X x) => x;

void f() {
  for (var e in [fun(ff<E>(.a, E.a), 2)]) {
    print(e);
  }
}
''');
  }

  Future<void> test_forEach_dotShorthands_list() async {
    await resolveTestCode('''
enum E { a }
void f() {
  for (E e in [.a]) {
    print(e);
  }
}
''');
    await assertHasFix('''
enum E { a }
void f() {
  for (var e in <E>[.a]) {
    print(e);
  }
}
''');
  }

  Future<void> test_forEach_dotShorthands_set() async {
    await resolveTestCode('''
enum E { a }
void f() {
  for (E e in {.a}) {
    print(e);
  }
}
''');
    await assertHasFix('''
enum E { a }
void f() {
  for (var e in <E>{.a}) {
    print(e);
  }
}
''');
  }

  Future<void> test_forEach_final() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (final int i in list) {
    print(i);
  }
}
''');
    await assertHasFix('''
void f(List<int> list) {
  for (final i in list) {
    print(i);
  }
}
''');
  }

  Future<void> test_generic_instanceCreation_cascade_dotShorthand() async {
    await resolveTestCode('''
enum E { a }
Set f() {
  Set<E> s = { .a }..addAll([]);
  return s;
}
''');
    await assertHasFix('''
enum E { a }
Set f() {
  var s = <E>{ .a }..addAll([]);
  return s;
}
''');
  }

  Future<void>
  test_generic_instanceCreation_withoutArguments_dotShorthand() async {
    await resolveTestCode('''
C<int> f() {
  C<int> c = .new();
  return c;
}
class C<T> {}
''');
    await assertHasFix('''
C<int> f() {
  var c = C<int>.new();
  return c;
}
class C<T> {}
''');
  }

  Future<void>
  test_generic_instanceCreation_withoutArguments_dotShorthand_parameter() async {
    await resolveTestCode('''
class C<T> {
  C(T x);
}
enum E { a }
C<E> f() {
  C<E> c = C(.a);
  return c;
}
''');
    await assertHasFix('''
class C<T> {
  C(T x);
}
enum E { a }
C<E> f() {
  var c = C<E>(.a);
  return c;
}
''');
  }

  Future<void> test_generic_listLiteral_const() async {
    await resolveTestCode('''
String f() {
  const List<String> values = const ['a'];
  return values[0];
}
''');
    await assertHasFix('''
String f() {
  const values = const <String>['a'];
  return values[0];
}
''');
  }

  Future<void> test_generic_listLiteral_dotShorthand() async {
    await resolveTestCode('''
enum E { a, b }
List f() {
  List<E> l = [.a, .b];
  return l;
}
''');
    await assertHasFix('''
enum E { a, b }
List f() {
  var l = <E>[.a, .b];
  return l;
}
''');
  }

  Future<void> test_generic_mapLiteral_const() async {
    await resolveTestCode('''
Map f() {
  const Map<String, int> m = const {};
  return m;
}
''');
    await assertHasFix('''
Map f() {
  const m = const <String, int>{};
  return m;
}
''');
  }

  Future<void> test_generic_setLiteral_const() async {
    await resolveTestCode('''
String f() {
  const Set<String> s = const {'a'};
  return s.first;
}
''');
    await assertHasFix('''
String f() {
  const s = const <String>{'a'};
  return s.first;
}
''');
  }

  Future<void> test_simple_const() async {
    await resolveTestCode('''
String f() {
  const String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  const s = '';
  return s;
}
''');
  }

  Future<void> test_simple_dotShorthand_constructorInvocation() async {
    await resolveTestCode('''
class E {}
E f() {
  E e = .new();
  return e;
}
''');
    await assertHasFix('''
class E {}
E f() {
  var e = E.new();
  return e;
}
''');
  }

  Future<void> test_simple_dotShorthand_methodInvocation() async {
    await resolveTestCode('''
class E {
  static E method() => E();
}
E f() {
  E e = .method();
  return e;
}
''');
    await assertHasFix('''
class E {
  static E method() => E();
}
E f() {
  var e = E.method();
  return e;
}
''');
  }

  Future<void> test_simple_dotShorthand_propertyAccess() async {
    await resolveTestCode('''
enum E { a }
E f() {
  E e = .a;
  return e;
}
''');
    await assertHasFix('''
enum E { a }
E f() {
  var e = E.a;
  return e;
}
''');
  }

  Future<void> test_simple_final() async {
    await resolveTestCode('''
String f() {
  final String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  final s = '';
  return s;
}
''');
  }
}

@reflectiveTest
class OmitObviousLocalVariableTypesBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.omit_obvious_local_variable_types;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
List f() {
  const List<String> l = ['a'];
  return l;
}

void f2() {
  for (final String i in ['a']) {
    print(i);
  }
}
''');
    await assertHasFix('''
List f() {
  const l = <String>['a'];
  return l;
}

void f2() {
  for (final i in ['a']) {
    print(i);
  }
}
''');
  }
}

@reflectiveTest
class OmitObviousLocalVariableTypesLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeTypeAnnotation;

  @override
  String get lintCode => LintNames.omit_obvious_local_variable_types;

  Future<void> test_forEach_final() async {
    await resolveTestCode('''
void f() {
  for (final String s in ['a']) {
    print(s);
  }
}
''');
    await assertHasFix('''
void f() {
  for (final s in ['a']) {
    print(s);
  }
}
''');
  }

  Future<void> test_generic_listLiteral_const() async {
    await resolveTestCode('''
String f() {
  const List<String> values = const ['a'];
  return values[0];
}
''');
    await assertHasFix('''
String f() {
  const values = const <String>['a'];
  return values[0];
}
''');
  }

  Future<void> test_generic_mapLiteral_const() async {
    await resolveTestCode('''
Map f() {
  const Map<String, double> m = const {'a': 1.5};
  return m;
}
''');
    await assertHasFix('''
Map f() {
  const m = const <String, double>{'a': 1.5};
  return m;
}
''');
  }

  Future<void> test_generic_setLiteral_const() async {
    await resolveTestCode('''
String f() {
  const Set<String> s = const {'a'};
  return s.first;
}
''');
    await assertHasFix('''
String f() {
  const s = const <String>{'a'};
  return s.first;
}
''');
  }

  Future<void> test_simple_const() async {
    await resolveTestCode('''
String f() {
  const String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  const s = '';
  return s;
}
''');
  }

  Future<void> test_simple_final() async {
    await resolveTestCode('''
String f() {
  final String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  final s = '';
  return s;
}
''');
  }
}

@reflectiveTest
class OmitObviousPropertyTypesLintBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.omit_obvious_property_types;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
const List<String> l = ['a'];

class A {
  static final List<String> l = ['a'];
}
''');
    await assertHasFix('''
const l = <String>['a'];

class A {
  static final l = <String>['a'];
}
''');
  }
}

@reflectiveTest
class OmitObviousPropertyTypesLintLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeTypeAnnotation;

  @override
  String get lintCode => LintNames.omit_obvious_property_types;

  Future<void> test_generic_instanceCreation_withArguments() async {
    await resolveTestCode('''
final C<int> c = C<int>();

class C<T> {}
''');
    await assertHasFix('''
final c = C<int>();

class C<T> {}
''');
  }

  Future<void> test_generic_listLiteral_const() async {
    await resolveTestCode('''
const List<String> values = const ['a'];
''');
    await assertHasFix('''
const values = const <String>['a'];
''');
  }

  Future<void> test_generic_mapLiteral_const() async {
    await resolveTestCode('''
const Map<String, double> m = {'a': 1.5};
''');
    await assertHasFix('''
const m = <String, double>{'a': 1.5};
''');
  }

  Future<void> test_generic_setLiteral_const() async {
    await resolveTestCode('''
const Set<String> s = const {'a'};
''');
    await assertHasFix('''
const s = const <String>{'a'};
''');
  }

  Future<void> test_simple_const() async {
    await resolveTestCode('''
const String s = '';
''');
    await assertHasFix('''
const s = '';
''');
  }

  Future<void> test_simple_final() async {
    await resolveTestCode('''
final String s = '';
''');
    await assertHasFix('''
final s = '';
''');
  }

  Future<void> test_top_level_final() async {
    await resolveTestCode('''
final List<String> list = ['a'];
''');
    await assertHasFix('''
final list = <String>['a'];
''');
  }
}

@reflectiveTest
abstract class RemoveTypeAnnotationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeTypeAnnotation;
}

@reflectiveTest
class SuperFormalParameterTypeIsNotSubtypeOfAssociatedBulkTest
    extends BulkFixProcessorTest {
  Future<void> test_requiredPositional() async {
    await resolveTestCode('''
class C {
  C(String f);
}
class D extends C {
  D(int super.f);
  D.named(int super.f);
}
''');
    await assertHasFix('''
class C {
  C(String f);
}
class D extends C {
  D(super.f);
  D.named(super.f);
}
''');
  }
}

@reflectiveTest
class SuperFormalParameterTypeIsNotSubtypeOfAssociatedTest
    extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeTypeAnnotation;

  Future<void> test_functionTyped_parameterTypeIsNotSupertype() async {
    await resolveTestCode('''
class C {
  C(void f(num p));
}
class D extends C {
  D(void super.f(int p));
}
''');
    await assertHasFix('''
class C {
  C(void f(num p));
}
class D extends C {
  D(super.f);
}
''');
  }

  Future<void> test_functionTyped_returnTypeIsNotSubtype() async {
    await resolveTestCode('''
class C {
  C(int f());
}
class D extends C {
  D(num super.f());
}
''');
    await assertHasFix('''
class C {
  C(int f());
}
class D extends C {
  D(super.f);
}
''');
  }

  Future<void> test_optionalPositional() async {
    await resolveTestCode('''
class C {
  C([int f = 0]);
}
class D extends C {
  D([num super.f = 1]);
}
''');
    await assertHasFix('''
class C {
  C([int f = 0]);
}
class D extends C {
  D([super.f = 1]);
}
''');
  }

  Future<void> test_requiredPositional() async {
    await resolveTestCode('''
class C {
  C(String f);
}
class D extends C {
  D(int super.f);
}
''');
    await assertHasFix('''
class C {
  C(String f);
}
class D extends C {
  D(super.f);
}
''');
  }
}

@reflectiveTest
class TypeInitFormalsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.type_init_formals;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  int f;
  C(int this.f);
}

class Point {
  int x, y;
  Point(int this.x, int this.y);
}
''');
    await assertHasFix('''
class C {
  int f;
  C(this.f);
}

class Point {
  int x, y;
  Point(this.x, this.y);
}
''');
  }
}

@reflectiveTest
class TypeInitFormalsTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.type_init_formals;

  Future<void> test_formalFieldParameter() async {
    await resolveTestCode('''
class C {
  int f;
  C(int this.f);
}
''');
    await assertHasFix('''
class C {
  int f;
  C(this.f);
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3858')
  Future<void> test_functionTyped_parameterTypeIsNotSupertype() async {
    await resolveTestCode('''
class C {
  void Function(int) f;
  C(void this.f(int p));
}
''');
    await assertHasFix('''
class C {
  void Function(int) f;
  C(void this.f(int p));
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3858')
  Future<void> test_functionTyped_returnTypeIsNotSubtype() async {
    await resolveTestCode('''
class C {
  int Function() f;
  C(int this.f());
}
''');
    await assertHasFix('''
class C {
  int Function() f;
  C(this.f());
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3210')
  Future<void> test_superParameter() async {
    // If this issue gets closed as "won't fix," remove this test.
    await resolveTestCode('''
class C {
  C(int f);
}
class D extends C {
  D(int super.f);
}
''');
    await assertHasFix('''
class C {
  int f;
  C(super.f);
}
''');
  }
}

@reflectiveTest
class VarAndTypeTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeTypeAnnotation;

  Future<void> test_declaredVariablePattern() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case var int y:
      y;
  }
}
''');
    await assertHasFix('''
void f(Object? x) {
  switch (x) {
    case var y:
      y;
  }
}
''');
  }

  Future<void> test_variableDeclarationList() async {
    await resolveTestCode('''
void f() {
  var int v = 0;
  v;
}
''');
    await assertHasFix('''
void f() {
  var v = 0;
  v;
}
''');
  }
}
