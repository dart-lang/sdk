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
    defineReflectiveTests(ConvertIntoExpressionBodyTest);
  });
}

@reflectiveTest
class ConvertIntoExpressionBodyTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_INTO_EXPRESSION_BODY;

  @override
  String get lintCode => LintNames.prefer_expression_function_bodies;

  /// More coverage in the `convert_into_expression_body_test.dart` assist test.
  Future<void> test_async() async {
    await resolveTestCode('''
class A {
  mmm() async { 
    return 42;
  }
}
''');
    await assertHasFix('''
class A {
  mmm() async => 42;
}
''');
  }
}
