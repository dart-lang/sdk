// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveEmptyCatchTest);
  });
}

@reflectiveTest
class RemoveEmptyCatchTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.empty_catches;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  try {
    try {
      1;
    } catch (e) {} finally {}
  } catch (e) {} finally {}
}

void f2() {
  try {} catch (e) {} finally {}
}
''');
    await assertHasFix('''
void f() {
  try {
    try {
      1;
    } finally {}
  } finally {}
}

void f2() {
  try {} finally {}
}
''');
  }
}
