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
    defineReflectiveTests(RenameToCamelCaseTest);
  });
}

@reflectiveTest
class RenameToCamelCaseTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.RENAME_TO_CAMEL_CASE;

  @override
  String get lintCode => LintNames.non_constant_identifier_names;

  Future<void> test_localVariable() async {
    await resolveTestCode('''
main() {
  int my_integer_variable = 42;
  int foo;
  print(my_integer_variable);
  print(foo);
}
''');
    await assertHasFix('''
main() {
  int myIntegerVariable = 42;
  int foo;
  print(myIntegerVariable);
  print(foo);
}
''');
  }

  Future<void> test_parameter_closure() async {
    await resolveTestCode('''
main() {
  [0, 1, 2].forEach((my_integer_variable) {
    print(my_integer_variable);
  });
}
''');
    await assertHasFix('''
main() {
  [0, 1, 2].forEach((myIntegerVariable) {
    print(myIntegerVariable);
  });
}
''');
  }

  Future<void> test_parameter_function() async {
    await resolveTestCode('''
main(int my_integer_variable) {
  print(my_integer_variable);
}
''');
    await assertHasFix('''
main(int myIntegerVariable) {
  print(myIntegerVariable);
}
''');
  }

  Future<void> test_parameter_method() async {
    await resolveTestCode('''
class A {
  main(int my_integer_variable) {
    print(my_integer_variable);
  }
}
''');
    await assertHasFix('''
class A {
  main(int myIntegerVariable) {
    print(myIntegerVariable);
  }
}
''');
  }

  Future<void> test_parameter_optionalNamed() async {
    await resolveTestCode('''
foo({int my_integer_variable}) {
  print(my_integer_variable);
}
''');
    await assertNoFix();
  }

  Future<void> test_parameter_optionalPositional() async {
    await resolveTestCode('''
main([int my_integer_variable]) {
  print(my_integer_variable);
}
''');
    await assertHasFix('''
main([int myIntegerVariable]) {
  print(myIntegerVariable);
}
''');
  }
}
