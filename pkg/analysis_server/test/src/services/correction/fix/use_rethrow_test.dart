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
    defineReflectiveTests(UseRethrowBulkTest);
    defineReflectiveTests(UseRethrowTest);
  });
}

@reflectiveTest
class UseRethrowBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_rethrow_when_possible;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  try {} catch (e) {
    throw e;
  }
}

void f2() {
  try {} catch (e, stackTrace) {
    print(stackTrace);
    throw e;
  }
}
''');
    await assertHasFix('''
void f() {
  try {} catch (e) {
    rethrow;
  }
}

void f2() {
  try {} catch (e, stackTrace) {
    print(stackTrace);
    rethrow;
  }
}
''');
  }
}

@reflectiveTest
class UseRethrowTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.USE_RETHROW;

  @override
  String get lintCode => LintNames.use_rethrow_when_possible;

  Future<void> test_rethrow() async {
    await resolveTestCode('''
void bad1() {
  try {} catch (e) {
    throw e;
  }
}
''');
    await assertHasFix('''
void bad1() {
  try {} catch (e) {
    rethrow;
  }
}
''');
  }
}
