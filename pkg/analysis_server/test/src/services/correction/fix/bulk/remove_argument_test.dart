// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveArgumentTest);
  });
}

@reflectiveTest
class RemoveArgumentTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_redundant_argument_values;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f({bool valWithDefault = true, bool val}) {}
void f2({bool valWithDefault = true, bool val}) {}

void main() {
  f(valWithDefault: true);
  f2(valWithDefault: true, val: false);
}
''');
    await assertHasFix('''
void f({bool valWithDefault = true, bool val}) {}
void f2({bool valWithDefault = true, bool val}) {}

void main() {
  f();
  f2(val: false);
}
''');
  }
}
