// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithIsEmptyTest);
  });
}

@reflectiveTest
class ReplaceWithIsEmptyTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_is_empty;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(List c) {
  if (0 == c.length) {}
  if (1 > c.length) {}
}
''');
    await assertHasFix('''
void f(List c) {
  if (c.isEmpty) {}
  if (c.isEmpty) {}
}
''');
  }
}
