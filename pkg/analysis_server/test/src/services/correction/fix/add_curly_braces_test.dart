// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddCurlyBracesTest);
  });
}

@reflectiveTest
class AddCurlyBracesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_CURLY_BRACES;

  @override
  String get lintCode => LintNames.curly_braces_in_flow_control_structures;

  // More coverage in the `use_curly_braces_test.dart` assist test.

  Future<void> test_do_block() async {
    await resolveTestCode('''
main() {
  do print(0); while (true);
}
''');
    await assertHasFix('''
main() {
  do {
    print(0);
  } while (true);
}
''');
  }
}
