// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIfElementTest);
  });
}

@reflectiveTest
class ConvertToIfElementTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_IF_ELEMENT;

  @override
  String get lintCode =>
      LintNames.prefer_if_elements_to_conditional_expressions;

  // More coverage in the `convert_to_if_element_test.dart` assist test.
  Future<void> test_conditional_list() async {
    await resolveTestCode('''
f(bool b) {
  return ['a', b ? 'c' : 'd', 'e'];
}
''');
    await assertHasFix('''
f(bool b) {
  return ['a', if (b) 'c' else 'd', 'e'];
}
''');
  }
}
