// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoIsNotTest);
  });
}

@reflectiveTest
class ConvertIntoIsNotTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_is_not_operator;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(p) {
  !(p is String) && !!(p is String);
}
''');
    await assertHasFix('''
void f(p) {
  p is! String && !(p is! String);
}
''');
  }
}
