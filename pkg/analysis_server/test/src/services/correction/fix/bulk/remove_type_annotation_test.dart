// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDynamicTypeAnnotationTest);
  });
}

@reflectiveTest
class RemoveDynamicTypeAnnotationTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_annotating_with_dynamic;

  Future<void> test_singleFile() async {
    await resolveTestUnit('''
f(void foo(dynamic x)) {
  return null;
}

f2({dynamic defaultValue}) {
  return null;
}
''');
    await assertHasFix('''
f(void foo(x)) {
  return null;
}

f2({defaultValue}) {
  return null;
}
''');
  }
}
