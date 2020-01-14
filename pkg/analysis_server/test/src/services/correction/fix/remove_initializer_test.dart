// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
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

  test_field() async {
    await resolveTestUnit('''
class Test {
  int /*LINT*/x = null;
}
''');
    await assertHasFix('''
class Test {
  int /*LINT*/x;
}
''');
  }

  test_forLoop() async {
    await resolveTestUnit('''
void f() {
  for (var /*LINT*/i = null; i != null; i++) {
  }
}
''');
    await assertHasFix('''
void f() {
  for (var /*LINT*/i; i != null; i++) {
  }
}
''');
  }

  test_listOfVariableDeclarations() async {
    await resolveTestUnit('''
String a = 'a', /*LINT*/b = null, c = 'c';
''');
    await assertHasFix('''
String a = 'a', /*LINT*/b, c = 'c';
''');
  }

  test_parameter_optionalNamed() async {
    await resolveTestUnit('''
void f({String /*LINT*/s = null}) {}
''');
    await assertHasFix('''
void f({String /*LINT*/s}) {}
''');
  }

  test_parameter_optionalPositional() async {
    await resolveTestUnit('''
void f([String /*LINT*/s = null]) {}
''');
    await assertHasFix('''
void f([String /*LINT*/s]) {}
''');
  }

  test_topLevel() async {
    await resolveTestUnit('''
var /*LINT*/x = null;
''');
    await assertHasFix('''
var /*LINT*/x;
''');
  }
}
