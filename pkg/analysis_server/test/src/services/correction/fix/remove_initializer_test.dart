// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveInitializerTest);
  });
}

@reflectiveTest
class RemoveInitializerTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_INITIALIZER;

  @override
  String get lintCode => LintNames.avoid_init_to_null;

  Future<void> test_field() async {
    await resolveTestCode('''
class Test {
  int x = null;
}
''');
    await assertHasFix('''
class Test {
  int x;
}
''');
  }

  Future<void> test_forLoop() async {
    await resolveTestCode('''
void f() {
  for (var i = null; i != null; i++) {
  }
}
''');
    await assertHasFix('''
void f() {
  for (var i; i != null; i++) {
  }
}
''');
  }

  Future<void> test_listOfVariableDeclarations() async {
    await resolveTestCode('''
String a = 'a', b = null, c = 'c';
''');
    await assertHasFix('''
String a = 'a', b, c = 'c';
''');
  }

  Future<void> test_parameter_optionalNamed() async {
    await resolveTestCode('''
void f({String s = null}) {}
''');
    await assertHasFix('''
void f({String s}) {}
''');
  }

  Future<void> test_parameter_optionalPositional() async {
    await resolveTestCode('''
void f([String s = null]) {}
''');
    await assertHasFix('''
void f([String s]) {}
''');
  }

  Future<void> test_topLevel() async {
    await resolveTestCode('''
var x = null;
''');
    await assertHasFix('''
var x;
''');
  }
}
