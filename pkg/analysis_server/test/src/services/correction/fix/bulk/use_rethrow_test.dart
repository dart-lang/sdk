// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseRethrowTest);
  });
}

@reflectiveTest
class UseRethrowTest extends BulkFixProcessorTest {
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
