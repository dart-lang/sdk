// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseIsNotEmptyTest);
  });
}

@reflectiveTest
class UseIsNotEmptyTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_is_not_empty;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(List<int> l) {
  if (!l.isEmpty) {}
  if (!l.isEmpty || true) {}
}
''');
    await assertHasFix('''
void f(List<int> l) {
  if (l.isNotEmpty) {}
  if (l.isNotEmpty || true) {}
}
''');
  }
}
