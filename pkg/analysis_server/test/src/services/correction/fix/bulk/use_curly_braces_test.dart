// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseCurlyBracesTest);
  });
}

@reflectiveTest
class UseCurlyBracesTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.curly_braces_in_flow_control_structures;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() {
  while (true) if (false) print('');
}

f2() {
  while (true) print(2);
}
''');
    await assertHasFix('''
f() {
  while (true) if (false) {
    print('');
  }
}

f2() {
  while (true) {
    print(2);
  }
}
''');
  }
}
