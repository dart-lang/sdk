// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryStringInterpolation);
  });
}

@reflectiveTest
class RemoveUnnecessaryStringInterpolation extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_string_interpolations;

  Future<void> test_embedded_removeBoth() async {
    await resolveTestCode(r'''
void f(String s) {
  print('${'$s'}');
}
''');
    await assertHasFix(r'''
void f(String s) {
  print(s);
}
''');
  }

  Future<void> test_embedded_removeOuter() async {
    await resolveTestCode(r'''
void f(String s) {
  print('${'$s '}');
}
''');
    await assertHasFix(r'''
void f(String s) {
  print('$s ');
}
''');
  }
}
