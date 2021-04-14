// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveEmptyStatementTest);
  });
}

@reflectiveTest
class RemoveEmptyStatementTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.empty_statements;

  Future<void> test_singleFile() async {
    // Note that ReplaceWithEmptyBrackets is not supported.
    //   for example: `if (true) ;` ...
    await resolveTestCode('''
void f() {
  while(true) {
    ;
  }
}

void f2() {
  while(true) { ; }
}
''');
    await assertHasFix('''
void f() {
  while(true) {
  }
}

void f2() {
  while(true) { }
}
''');
  }
}
