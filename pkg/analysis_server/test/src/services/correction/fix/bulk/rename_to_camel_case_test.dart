// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameToCamelCaseTest);
  });
}

@reflectiveTest
class RenameToCamelCaseTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.non_constant_identifier_names;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
main() {
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
main() {
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
