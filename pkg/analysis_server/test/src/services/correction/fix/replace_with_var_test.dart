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
  FixKind get kind => DartFixKind.REPLACE_WITH_VAR;

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
    await assertHasFix('''
String f() {
  const values = const <String>['a'];
  return values[0];
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
    await assertHasFix('''
Map f() {
  const m = const <String, int>{};
  return m;
}
''');
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
    await assertHasFix('''
String f() {
  const s = const <String>{'a'};
  return s.first;
}
''');
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
  FixKind get kind => DartFixKind.REPLACE_WITH_VAR;

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
    await assertHasFix('''
void f() {
  for (final s in ['a']) {
    print(s);
  }
}
''');
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
    await assertHasFix('''
String f() {
  const values = const <String>['a'];
  return values[0];
}
''');
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
    await assertHasFix('''
Map f() {
  const m = const <String, double>{'a': 1.5};
  return m;
}
''');
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
    await assertHasFix('''
String f() {
  const s = const <String>{'a'};
  return s.first;
}
''');
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
  FixKind get kind => DartFixKind.REPLACE_WITH_VAR;

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
    await assertHasFix('''
final c = C<int>();

class C<T> {}
''');
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
    await assertHasFix('''
const values = const <String>['a'];
''');
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
    await assertHasFix('''
const m = <String, double>{'a': 1.5};
''');
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
    await assertHasFix('''
const s = const <String>{'a'};
''');
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
    await assertHasFix('''
final list = <String>['a'];
''');
  }
}
