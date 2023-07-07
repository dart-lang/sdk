// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonFinalFieldInEnumTest);
    defineReflectiveTests(PreferFinalFieldsBulkTest);
    defineReflectiveTests(PreferFinalFieldsTest);
    defineReflectiveTests(PreferFinalFieldsWithNullSafetyTest);
    defineReflectiveTests(PreferFinalInForEachTest);
    defineReflectiveTests(PreferFinalLocalTest);
    defineReflectiveTests(PreferFinalLocalsBulkTest);
    defineReflectiveTests(PreferFinalParametersTest);
    defineReflectiveTests(PreferFinalParametersBulkTest);
  });
}

@reflectiveTest
class NonFinalFieldInEnumTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.MAKE_FINAL;

  Future<void> test_field_type() async {
    await resolveTestCode('''
enum E {
  one, two;
  int f = 2;
}
''');
    await assertHasFix('''
enum E {
  one, two;
  final int f = 2;
}
''');
  }

  Future<void> test_field_var() async {
    await resolveTestCode('''
enum E {
  one, two;
  var f = 2;
}
''');
    await assertHasFix('''
enum E {
  one, two;
  final f = 2;
}
''');
  }
}

@reflectiveTest
class PreferFinalFieldsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_final_fields;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  int _f = 2;
  var _f2 = 2;
  int get g => _f;
  int get g2 => _f2;
}
''');
    await assertHasFix('''
class C {
  final int _f = 2;
  final _f2 = 2;
  int get g => _f;
  int get g2 => _f2;
}
''');
  }
}

@reflectiveTest
class PreferFinalFieldsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_FINAL;

  @override
  String get lintCode => LintNames.prefer_final_fields;

  Future<void> test_field_type() async {
    await resolveTestCode('''
class C {
  int _f = 2;
  int get g => _f;
}
''');
    await assertHasFix('''
class C {
  final int _f = 2;
  int get g => _f;
}
''');
  }

  Future<void> test_field_var() async {
    await resolveTestCode('''
class C {
  var _f = 2;
  int get g => _f;
}
''');
    await assertHasFix('''
class C {
  final _f = 2;
  int get g => _f;
}
''');
  }
}

@reflectiveTest
class PreferFinalFieldsWithNullSafetyTest extends FixProcessorLintTest
    with WithNullSafetyLintMixin {
  @override
  FixKind get kind => DartFixKind.MAKE_FINAL;

  @override
  String get lintCode => LintNames.prefer_final_fields;

  Future<void> test_lateField_type() async {
    await resolveTestCode('''
class C {
  late int _f = 2;
  int get g => _f;
}
''');
    await assertHasFix('''
class C {
  late final int _f = 2;
  int get g => _f;
}
''');
  }

  Future<void> test_lateField_var() async {
    await resolveTestCode('''
class C {
  late var _f = 2;
  int get g => _f;
}
''');
    await assertHasFix('''
class C {
  late final _f = 2;
  int get g => _f;
}
''');
  }
}

@reflectiveTest
class PreferFinalInForEachTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_FINAL;

  @override
  String get lintCode => LintNames.prefer_final_in_for_each;

  Future<void> test_inList() async {
    await resolveTestCode('''
f() {
  var l = [ for (var i in [1, 2]) i + 3 ];
}
''');
    await assertHasFix('''
f() {
  var l = [ for (final i in [1, 2]) i + 3 ];
}
''', errorFilter: (e) => e.errorCode != WarningCode.UNUSED_LOCAL_VARIABLE);
  }

  Future<void> test_listPattern() async {
    await resolveTestCode('''
f() {
  for (var [i, j] in [[1, 2]]) { }
}
''');
    await assertHasFix('''
f() {
  for (final [i, j] in [[1, 2]]) { }
}
''', errorFilter: (e) => e.errorCode != WarningCode.UNUSED_LOCAL_VARIABLE);
  }

  Future<void> test_mapPattern() async {
    await resolveTestCode('''
f() {
  for (var {'i' : j} in [{'i' : 1}]) { }
}
''');
    await assertHasFix('''
f() {
  for (final {'i' : j} in [{'i' : 1}]) { }
}
''', errorFilter: (e) => e.errorCode != WarningCode.UNUSED_LOCAL_VARIABLE);
  }

  Future<void> test_noType() async {
    await resolveTestCode('''
void fn() {
  for (var i in [1, 2, 3]) {
    print(i);
  }
}
''');
    await assertHasFix('''
void fn() {
  for (final i in [1, 2, 3]) {
    print(i);
  }
}
''');
  }

  Future<void> test_objectPattern() async {
    await resolveTestCode('''
class A {
  int a;
  A(this.a);
}

f() {
  for (var A(:a) in [A(1)]) { }
} 
''');
    await assertHasFix('''
class A {
  int a;
  A(this.a);
}

f() {
  for (final A(:a) in [A(1)]) { }
} 
''', errorFilter: (e) => e.errorCode != WarningCode.UNUSED_LOCAL_VARIABLE);
  }

  Future<void> test_recordPattern() async {
    await resolveTestCode('''
f() {
  for (var (i, j) in [(1, 2)]) { }
}
''');
    await assertHasFix('''
f() {
  for (final (i, j) in [(1, 2)]) { }
}
''', errorFilter: (e) => e.errorCode != WarningCode.UNUSED_LOCAL_VARIABLE);
  }

  Future<void> test_type() async {
    await resolveTestCode('''
void fn() {
  for (int i in [1, 2, 3]) {
    print(i);
  }
}
''');
    await assertHasFix('''
void fn() {
  for (final int i in [1, 2, 3]) {
    print(i);
  }
}
''');
  }
}

@reflectiveTest
class PreferFinalLocalsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_final_locals;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() {
  var x = 0;
  var y = x;
}
''');
    await assertHasFix('''
f() {
  final x = 0;
  final y = x;
}
''');
  }
}

@reflectiveTest
class PreferFinalLocalTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_FINAL;

  @override
  String get lintCode => LintNames.prefer_final_locals;

  Future<void> test_listPattern_assignment() async {
    await resolveTestCode(r'''
f() {
  var [a] = [1];
  print(a);
}
''');
    await assertHasFix(r'''
f() {
  final [a] = [1];
  print(a);
}
''');
  }

  Future<void> test_listPattern_ifCase_noVar() async {
    await resolveTestCode(r'''
void f(Object o) {
  if (o case [int x]) print(x);
}
''');
    await assertHasFix(r'''
void f(Object o) {
  if (o case [final int x]) print(x);
}
''');
  }

  Future<void> test_listPattern_ifCase_untyped() async {
    await resolveTestCode(r'''
void f(Object o) {
  if (o case <int>[var x]) print(x);
}
''');
    await assertHasFix(r'''
void f(Object o) {
  if (o case <int>[final x]) print(x);
}
''');
  }

  Future<void> test_recordPattern_assignment() async {
    await resolveTestCode(r'''
f() {
  var (a, b) = (1, 2);
  print('$a$b');
}
''');
    await assertHasFix(r'''
f() {
  final (a, b) = (1, 2);
  print('$a$b');
}
''');
  }

  Future<void> test_recordPattern_declarationNestedIn_forLoop() async {
    await resolveTestCode(r'''
f() {
  for (var (a, b) in g(() {
        var (c, d) = (0, 1);
        return (c, d);
      })) {
    a++;
    b++;
    print(a + b);
  }
}

List<(int, int)> g((int, int) Function() f) {
  return [f()];
}
''');
    await assertHasFix(r'''
f() {
  for (var (a, b) in g(() {
        final (c, d) = (0, 1);
        return (c, d);
      })) {
    a++;
    b++;
    print(a + b);
  }
}

List<(int, int)> g((int, int) Function() f) {
  return [f()];
}
''');
  }

  Future<void> test_recordPattern_forLoop() async {
    await resolveTestCode(r'''
f() {
  for (var (a) in [(1)]) {
    print('$a');
  }
}
''');
    await assertHasFix(r'''
f() {
  for (final (a) in [(1)]) {
    print('$a');
  }
}
''');
  }

  Future<void> test_variableDeclarationStatement_type() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = 0;
}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  final int v = 0;
}
''');
  }

  Future<void> test_variableDeclarationStatement_var() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  var v = 0;
}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  final v = 0;
}
''');
  }
}

@reflectiveTest
class PreferFinalParametersBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_final_parameters;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void fn(String test, int other) {
  print(test);
  print(other);
}
''');
    await assertHasFix('''
void fn(final String test, final int other) {
  print(test);
  print(other);
}
''');
  }
}

@reflectiveTest
class PreferFinalParametersTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_FINAL;

  @override
  String get lintCode => LintNames.prefer_final_parameters;

  Future<void> test_class_constructor() async {
    await resolveTestCode('''
class C {
  C(String content) {
    print(content);
  }
}
''');
    await assertHasFix('''
class C {
  C(final String content) {
    print(content);
  }
}
''');
  }

  Future<void> test_class_requiredCovariant() async {
    await resolveTestCode('''
class C {
  void fn({required covariant String test}) {
    print(test);
  }
}
''');
    await assertHasFix('''
class C {
  void fn({required covariant final String test}) {
    print(test);
  }
}
''');
  }

  Future<void> test_closure_hasType() async {
    await resolveTestCode('''
void fn() {
  ['1', '2', '3'].forEach((String string) => print(string));
}
''');
    await assertHasFix('''
void fn() {
  ['1', '2', '3'].forEach((final String string) => print(string));
}
''');
  }

  Future<void> test_closure_noType() async {
    await resolveTestCode('''
void fn() {
  ['1', '2', '3'].forEach((string) => print(string));
}
''');
    await assertHasFix('''
void fn() {
  ['1', '2', '3'].forEach((final string) => print(string));
}
''');
  }

  Future<void> test_functionLiteral() async {
    await resolveTestCode('''
var fn = (String test) {
  print(test);
};
''');
    await assertHasFix('''
var fn = (final String test) {
  print(test);
};
''');
  }

  Future<void> test_named_optional() async {
    await resolveTestCode('''
void fn({String? test}) {
  print(test);
}
''');
    await assertHasFix('''
void fn({final String? test}) {
  print(test);
}
''');
  }

  Future<void> test_named_optional_withDefault() async {
    await resolveTestCode('''
void fn({String test = 'value'}) {
  print(test);
}
''');
    await assertHasFix('''
void fn({final String test = 'value'}) {
  print(test);
}
''');
  }

  Future<void> test_named_required() async {
    await resolveTestCode('''
void fn({required String test}) {
  print(test);
}
''');
    await assertHasFix('''
void fn({required final String test}) {
  print(test);
}
''');
  }

  Future<void> test_positional_optional() async {
    await resolveTestCode('''
void fn([String? test]) {
  print(test);
}
''');
    await assertHasFix('''
void fn([final String? test]) {
  print(test);
}
''');
  }

  Future<void> test_positional_optional_withDefault() async {
    await resolveTestCode('''
void fn([String? test = 'value']) {
  print(test);
}
''');
    await assertHasFix('''
void fn([final String? test = 'value']) {
  print(test);
}
''');
  }

  Future<void> test_simple_hasType() async {
    await resolveTestCode('''
void fn(String test) {
  print(test);
}
''');
    await assertHasFix('''
void fn(final String test) {
  print(test);
}
''');
  }

  Future<void> test_simple_noType() async {
    await resolveTestCode('''
void fn(test) {
  print(test);
}
''');
    await assertHasFix('''
void fn(final test) {
  print(test);
}
''');
  }

  Future<void> test_simple_nullable() async {
    await resolveTestCode('''
void fn(String? test) {
  print(test);
}
''');
    await assertHasFix('''
void fn(final String? test) {
  print(test);
}
''');
  }

  Future<void> test_simple_second() async {
    await resolveTestCode('''
void fn(final String test, String other) {
  print(test);
  print(other);
}
''');
    await assertHasFix('''
void fn(final String test, final String other) {
  print(test);
  print(other);
}
''');
  }

  Future<void> test_simple_var() async {
    await resolveTestCode('''
void fn(var test) {
  print(test);
}
''');
    await assertHasFix('''
void fn(final test) {
  print(test);
}
''');
  }
}
