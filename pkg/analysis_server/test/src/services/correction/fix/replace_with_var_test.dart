// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OmitLocalVariableTypesLintBulkTest);
    defineReflectiveTests(OmitLocalVariableTypesLintTest);
    defineReflectiveTests(OmitObviousLocalVariableTypesLintBulkTest);
    defineReflectiveTests(OmitObviousLocalVariableTypesLintTest);
    defineReflectiveTests(OmitObviousPropertyTypesLintBulkTest);
    defineReflectiveTests(OmitObviousPropertyTypesLintTest);
  });
}

@reflectiveTest
class OmitLocalVariableTypesLintBulkTest extends BulkFixProcessorTest {
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
  List<int> l = [];
  return l;
}

void f2(List<int> list) {
  for (int i in list) {
    print(i);
  }
}
''');
    await assertHasFix('''
List f() {
  var l = <int>[];
  return l;
}

void f2(List<int> list) {
  for (var i in list) {
    print(i);
  }
}
''');
  }
}

@reflectiveTest
class OmitLocalVariableTypesLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithVar;

  @override
  String get lintCode => LintNames.omit_local_variable_types;

  Future<void> test_for() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (int i = 0; i < list.length; i++) {
    print(i);
  }
}
''');
    await assertHasFix('''
void f(List<int> list) {
  for (var i = 0; i < list.length; i++) {
    print(i);
  }
}
''');
  }

  Future<void> test_forEach() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (int i in list) {
    print(i);
  }
}
''');
    await assertHasFix('''
void f(List<int> list) {
  for (var i in list) {
    print(i);
  }
}
''');
  }

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
    await assertNoFix();
  }

  Future<void> test_generic_instanceCreation_cascade() async {
    await resolveTestCode('''
Set f() {
  Set<String> s = Set<String>()..addAll([]);
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = Set<String>()..addAll([]);
  return s;
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

  Future<void> test_generic_instanceCreation_withArguments() async {
    await resolveTestCode('''
C<int> f() {
  C<int> c = C<int>();
  return c;
}
class C<T> {}
''');
    await assertHasFix('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
''');
  }

  Future<void> test_generic_instanceCreation_withoutArguments() async {
    await resolveTestCode('''
C<int> f() {
  C<int> c = C();
  return c;
}
class C<T> {}
''');
    await assertHasFix('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
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

  Future<void> test_generic_listLiteral() async {
    await resolveTestCode('''
List f() {
  List<int> l = [];
  return l;
}
''');
    await assertHasFix('''
List f() {
  var l = <int>[];
  return l;
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
    await assertNoFix();
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

  Future<void> test_generic_mapLiteral() async {
    await resolveTestCode('''
Map f() {
  Map<String, int> m = {};
  return m;
}
''');
    await assertHasFix('''
Map f() {
  var m = <String, int>{};
  return m;
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
    await assertNoFix();
  }

  Future<void> test_generic_setLiteral() async {
    await resolveTestCode('''
Set f() {
  Set<int> s = {};
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = <int>{};
  return s;
}
''');
  }

  Future<void> test_generic_setLiteral_ambiguous() async {
    await resolveTestCode('''
Set f() {
  Set s = {};
  return s;
}
''');
    await assertNoFix();
  }

  Future<void> test_generic_setLiteral_cascade() async {
    await resolveTestCode('''
Set f() {
  Set<String> s = {}..addAll([]);
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = <String>{}..addAll([]);
  return s;
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
    await assertNoFix();
  }

  Future<void> test_generic_setLiteral_recordType() async {
    await resolveTestCode('''
Set f() {
  Set<(int, int)> s = {};
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = <(int, int)>{};
  return s;
}
''');
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
String f() {
  String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  var s = '';
  return s;
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
    await assertNoFix();
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
    await assertNoFix();
  }

  Future<void> test_simple_recordType() async {
    await resolveTestCode(r'''
String f() {
  (int, String) r = (3, '');
  return r.$2;
}
''');
    await assertHasFix(r'''
String f() {
  var r = (3, '');
  return r.$2;
}
''');
  }
}

@reflectiveTest
class OmitObviousLocalVariableTypesLintBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.omit_obvious_local_variable_types;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
List f() {
  List<String> l = ['a'];
  return l;
}

void f2() {
  for (String i in ['a']) {
    print(i);
  }
}
''');
    await assertHasFix('''
List f() {
  var l = <String>['a'];
  return l;
}

void f2() {
  for (var i in ['a']) {
    print(i);
  }
}
''');
  }
}

@reflectiveTest
class OmitObviousLocalVariableTypesLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithVar;

  @override
  String get lintCode => LintNames.omit_obvious_local_variable_types;

  Future<void> test_for() async {
    await resolveTestCode('''
void f(List<String> list) {
  for (double d = 0.5; d < list.length; d += 1) {
    print(d);
  }
}
''');
    await assertHasFix('''
void f(List<String> list) {
  for (var d = 0.5; d < list.length; d += 1) {
    print(d);
  }
}
''');
  }

  Future<void> test_forEach() async {
    await resolveTestCode('''
void f() {
  for (String s in ['a']) {
    print(s);
  }
}
''');
    await assertHasFix('''
void f() {
  for (var s in ['a']) {
    print(s);
  }
}
''');
  }

  Future<void> test_forEach_final() async {
    await resolveTestCode('''
void f() {
  for (final String s in ['a']) {
    print(s);
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_generic_instanceCreation_cascade() async {
    await resolveTestCode('''
Set f() {
  Set<String> s = Set<String>()..addAll([]);
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = Set<String>()..addAll([]);
  return s;
}
''');
  }

  Future<void> test_generic_instanceCreation_withArguments() async {
    await resolveTestCode('''
C<int> f() {
  C<int> c = C<int>();
  return c;
}
class C<T> {}
''');
    await assertHasFix('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
''');
  }

  Future<void> test_generic_listLiteral() async {
    await resolveTestCode('''
List f() {
  List<int> l = <int>[];
  return l;
}
''');
    await assertHasFix('''
List f() {
  var l = <int>[];
  return l;
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
    await assertNoFix();
  }

  Future<void> test_generic_mapLiteral() async {
    await resolveTestCode('''
Map f() {
  Map<String, double> m = {'a': 1.5};
  return m;
}
''');
    await assertHasFix('''
Map f() {
  var m = <String, double>{'a': 1.5};
  return m;
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
    await assertNoFix();
  }

  Future<void> test_generic_setLiteral() async {
    await resolveTestCode('''
Set f() {
  Set<double> s = {1.5};
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = <double>{1.5};
  return s;
}
''');
  }

  Future<void> test_generic_setLiteral_cascade() async {
    await resolveTestCode('''
Set f() {
  Set<String> s = {'a'}..addAll([]);
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = <String>{'a'}..addAll([]);
  return s;
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
    await assertNoFix();
  }

  Future<void> test_generic_setLiteral_recordType() async {
    await resolveTestCode('''
Set f() {
  Set<(double, double)> s = {(1.5, 2.5)};
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = <(double, double)>{(1.5, 2.5)};
  return s;
}
''');
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
String f() {
  String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  var s = '';
  return s;
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
    await assertNoFix();
  }

  Future<void> test_simple_final() async {
    await resolveTestCode('''
String f() {
  final String s = '';
  return s;
}
''');
    await assertNoFix();
  }

  Future<void> test_simple_recordType() async {
    await resolveTestCode(r'''
String f() {
  (double, String) r = (3.5, '');
  return r.$2;
}
''');
    await assertHasFix(r'''
String f() {
  var r = (3.5, '');
  return r.$2;
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
List<String> l = ['a'];

class A {
  static List<String> l = ['a'];
}
''');
    await assertHasFix('''
var l = <String>['a'];

class A {
  static var l = <String>['a'];
}
''');
  }
}

@reflectiveTest
class OmitObviousPropertyTypesLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithVar;

  @override
  String get lintCode => LintNames.omit_obvious_property_types;

  Future<void> test_generic_instanceCreation_cascade() async {
    await resolveTestCode('''
Set<String> s = Set<String>()..addAll([]);
''');
    await assertHasFix('''
var s = Set<String>()..addAll([]);
''');
  }

  Future<void> test_generic_instanceCreation_withArguments() async {
    await resolveTestCode('''
final C<int> c = C<int>();

class C<T> {}
''');
    await assertNoFix();
  }

  Future<void> test_generic_listLiteral() async {
    await resolveTestCode('''
List<num> l = <num>[x];

int x = 2 + 'Not obvious'.length;
''');
    await assertHasFix('''
var l = <num>[x];

int x = 2 + 'Not obvious'.length;
''');
  }

  Future<void> test_generic_listLiteral_const() async {
    await resolveTestCode('''
const List<String> values = const ['a'];
''');
    await assertNoFix();
  }

  Future<void> test_generic_mapLiteral() async {
    await resolveTestCode('''
Map<String, double> m = {'a': 1.5};
''');
    await assertHasFix('''
var m = <String, double>{'a': 1.5};
''');
  }

  Future<void> test_generic_mapLiteral_const() async {
    await resolveTestCode('''
const Map<String, double> m = {'a': 1.5};
''');
    await assertNoFix();
  }

  Future<void> test_generic_setLiteral() async {
    await resolveTestCode('''
Set<double> s = {1.5};
''');
    await assertHasFix('''
var s = <double>{1.5};
''');
  }

  Future<void> test_generic_setLiteral_cascade() async {
    await resolveTestCode('''
Set<String> s = {'a'}..addAll([]);
''');
    await assertHasFix('''
var s = <String>{'a'}..addAll([]);
''');
  }

  Future<void> test_generic_setLiteral_const() async {
    await resolveTestCode('''
const Set<String> s = const {'a'};
''');
    await assertNoFix();
  }

  Future<void> test_generic_setLiteral_recordType() async {
    await resolveTestCode('''
Set<(double, double)> s = {(1.5, 2.5)};
''');
    await assertHasFix('''
var s = <(double, double)>{(1.5, 2.5)};
''');
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
String s = '';
''');
    await assertHasFix('''
var s = '';
''');
  }

  Future<void> test_simple_const() async {
    await resolveTestCode('''
const String s = '';
''');
    await assertNoFix();
  }

  Future<void> test_simple_final() async {
    await resolveTestCode('''
final String s = '';
''');
    await assertNoFix();
  }

  Future<void> test_simple_recordType() async {
    await resolveTestCode(r'''
(double, String) r = (3.5, '');
''');
    await assertHasFix(r'''
var r = (3.5, '');
''');
  }

  Future<void> test_top_level() async {
    await resolveTestCode('''
List<String> list = ['a'];
''');
    await assertHasFix('''
var list = <String>['a'];
''');
  }

  Future<void> test_top_level_final() async {
    await resolveTestCode('''
final List<String> list = ['a'];
''');
    await assertNoFix();
  }
}
