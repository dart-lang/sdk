// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIfElementTest);
  });
}

@reflectiveTest
class ConvertToIfElementTest extends BulkFixProcessorTest {
  @override
  String get lintCode =>
      LintNames.prefer_if_elements_to_conditional_expressions;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
String f(bool b) {
  return ['a', b ? 'c' : 'd', 'e'];
}

String f2(bool b) {
  return {'a', b ? 'c' : 'd', 'e'};
}
''');
    await assertHasFix('''
String f(bool b) {
  return ['a', if (b) 'c' else 'd', 'e'];
}

String f2(bool b) {
  return {'a', if (b) 'c' else 'd', 'e'};
}
''');
  }
}
