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
    defineReflectiveTests(ReplaceWithTearOffTest);
  });
}

@reflectiveTest
class ReplaceWithTearOffTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_TEAR_OFF;

  @override
  String get lintCode => LintNames.unnecessary_lambdas;

  Future<void> test_function_oneParameter() async {
    await resolveTestCode('''
Function f() => (name) {
  print(name);
};
''');
    await assertHasFix('''
Function f() => print;
''');
  }

  Future<void> test_function_zeroParameters() async {
    await resolveTestCode('''
void foo(){}
Function finalVar() {
  return () {
    foo();
  };
}
''');
    await assertHasFix('''
void foo(){}
Function finalVar() {
  return foo;
}
''');
  }

  Future<void> test_lambda_asArgument() async {
    await resolveTestCode('''
void foo() {
  bool isPair(int a) => a % 2 == 0;
  final finalList = <int>[];
  finalList.where((number) =>
    isPair(number));
}
''');
    await assertHasFix('''
void foo() {
  bool isPair(int a) => a % 2 == 0;
  final finalList = <int>[];
  finalList.where(isPair);
}
''');
  }

  Future<void> test_method_oneParameter() async {
    await resolveTestCode('''
final l = <int>[];
var a = (x) => l.indexOf(x);
''');
    await assertHasFix('''
final l = <int>[];
var a = l.indexOf;
''');
  }

  Future<void> test_method_zeroParameter() async {
    await resolveTestCode('''
final Object a = '';
Function finalVar() {
  return () {
    return a.toString();
  };
}
''');
    await assertHasFix('''
final Object a = '';
Function finalVar() {
  return a.toString;
}
''');
  }
}
