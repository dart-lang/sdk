// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveAwaitTest);
  });
}

@reflectiveTest
class RemoveAwaitTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.await_only_futures;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() async {
  print(await 23);
}

f2() async {
  print(await 'hola');
}
''');
    await assertHasFix('''
f() async {
  print(23);
}

f2() async {
  print('hola');
}
''');
  }
}
