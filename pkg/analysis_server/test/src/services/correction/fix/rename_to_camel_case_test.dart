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
    defineReflectiveTests(RenameToCamelCaseBulkTest);
    defineReflectiveTests(RenameToCamelCaseTest_constantIdentifiedNames);
    defineReflectiveTests(RenameToCamelCaseTest_notConstantIdentifiedNames);
  });
}

@reflectiveTest
class RenameToCamelCaseBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.non_constant_identifier_names;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  int my_integer_variable = 42;
  int foo;
  print(my_integer_variable);
  print(foo);
  [0, 1, 2].forEach((my_integer_variable) {
    print(my_integer_variable);
  });
}
''');
    await assertHasFix('''
void f() {
  int myIntegerVariable = 42;
  int foo;
  print(myIntegerVariable);
  print(foo);
  [0, 1, 2].forEach((myIntegerVariable) {
    print(myIntegerVariable);
  });
}
''');
  }
}

@reflectiveTest
class RenameToCamelCaseTest_constantIdentifiedNames
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.RENAME_TO_CAMEL_CASE;

  @override
  String get lintCode => LintNames.constant_identifier_names;

  Future<void> test_localVariable_const() async {
    await resolveTestCode('''
void f() {
  const my_integer_variable = 0;
  my_integer_variable;
}
''');
    await assertHasFix('''
void f() {
  const myIntegerVariable = 0;
  myIntegerVariable;
}
''');
  }

  Future<void> test_topVariable_const() async {
    await resolveTestCode('''
const my_integer_variable = 0;

void f() {
  my_integer_variable;
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class RenameToCamelCaseTest_notConstantIdentifiedNames
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.RENAME_TO_CAMEL_CASE;

  @override
  String get lintCode => LintNames.non_constant_identifier_names;

  Future<void> test_localVariable_final() async {
    await resolveTestCode('''
void f() {
  final my_integer_variable = 0;
  my_integer_variable;
}
''');
    await assertHasFix('''
void f() {
  final myIntegerVariable = 0;
  myIntegerVariable;
}
''');
  }

  Future<void> test_localVariable_typed() async {
    await resolveTestCode('''
void f() {
  int my_integer_variable = 0;
  my_integer_variable;
}
''');
    await assertHasFix('''
void f() {
  int myIntegerVariable = 0;
  myIntegerVariable;
}
''');
  }

  Future<void> test_parameter_closure() async {
    await resolveTestCode('''
void f() {
  [0, 1, 2].forEach((my_integer_variable) {
    print(my_integer_variable);
  });
}
''');
    await assertHasFix('''
void f() {
  [0, 1, 2].forEach((myIntegerVariable) {
    print(myIntegerVariable);
  });
}
''');
  }

  Future<void> test_parameter_function() async {
    await resolveTestCode('''
void f(int my_integer_variable) {
  print(my_integer_variable);
}
''');
    await assertHasFix('''
void f(int myIntegerVariable) {
  print(myIntegerVariable);
}
''');
  }

  Future<void> test_parameter_function_screamingCaps() async {
    await resolveTestCode('''
void f(int FIRST_PARAMETER) {
  print(FIRST_PARAMETER);
}
''');
    await assertHasFix('''
void f(int firstParameter) {
  print(firstParameter);
}
''');
  }

  Future<void> test_parameter_method() async {
    await resolveTestCode('''
class A {
  void f(int my_integer_variable) {
    print(my_integer_variable);
  }
}
''');
    await assertHasFix('''
class A {
  void f(int myIntegerVariable) {
    print(myIntegerVariable);
  }
}
''');
  }

  Future<void> test_parameter_optionalNamed() async {
    await resolveTestCode('''
void f({int? my_integer_variable}) {
  print(my_integer_variable);
}
''');
    await assertNoFix();
  }

  Future<void> test_parameter_optionalPositional() async {
    await resolveTestCode('''
void f([int? my_integer_variable]) {
  print(my_integer_variable);
}
''');
    await assertHasFix('''
void f([int? myIntegerVariable]) {
  print(myIntegerVariable);
}
''');
  }

  Future<void> test_recordField() async {
    await resolveTestCode('''
void f(({int some_field}) p) {}
''');
    await assertHasFix('''
void f(({int someField}) p) {}
''');
  }
}
