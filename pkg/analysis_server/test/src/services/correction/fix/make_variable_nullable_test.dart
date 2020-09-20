// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeVariableNullableTest);
  });
}

@reflectiveTest
class MakeVariableNullableTest extends FixProcessorTest {
  @override
  List<String> get experiments => [EnableString.non_nullable];

  @override
  FixKind get kind => DartFixKind.MAKE_VARIABLE_NULLABLE;

  Future<void> test_lhsNotIdentifier() async {
    await resolveTestUnit('''
void f(C c) {
  c.s = null;
}
class C {
  String s = '';
}
''');
    await assertNoFix();
  }

  Future<void> test_lhsNotLocalVariable() async {
    await resolveTestUnit('''
var s = '';
void f() {
  s = null;
  print(s);
}
''');
    await assertNoFix();
  }

  Future<void> test_multipleVariables() async {
    await resolveTestUnit('''
void f() {
  var s = '', t = '';
  s = null;
  print(s);
  print(t);
}
''');
    await assertNoFix();
  }

  Future<void> test_noKeywordOrType() async {
    await resolveTestUnit('''
void f() {
  late s = '';
  s = null;
  print(s);
}
''');
    await assertHasFix('''
void f() {
  late String? s = '';
  s = null;
  print(s);
}
''');
  }

  Future<void> test_type() async {
    await resolveTestUnit('''
void f() {
  String s = '';
  s = null;
  print(s);
}
''');
    await assertHasFix('''
void f() {
  String? s = '';
  s = null;
  print(s);
}
''');
  }

  Future<void> test_var() async {
    await resolveTestUnit('''
void f() {
  var s = '';
  s = null;
  print(s);
}
''');
    await assertHasFix('''
void f() {
  String? s = '';
  s = null;
  print(s);
}
''');
  }
}
