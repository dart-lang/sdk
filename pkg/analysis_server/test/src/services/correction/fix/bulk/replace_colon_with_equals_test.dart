// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceColonWithEqualsTest);
  });
}

@reflectiveTest
class ReplaceColonWithEqualsTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_equal_for_default_values;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f({int a: 1}) => null;

class C {
  void m({int a: 1, int b: 2}) => null;
}
''');
    await assertHasFix('''
void f({int a = 1}) => null;

class C {
  void m({int a = 1, int b = 2}) => null;
}
''');
  }
}
