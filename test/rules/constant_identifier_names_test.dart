// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantIdentifierNamesRecordsTest);
  });
}

@reflectiveTest
class ConstantIdentifierNamesRecordsTest extends LintRuleTest {
  @override
  List<String> get experiments => ['records'];

  @override
  String get lintRule => 'constant_identifier_names';

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3630')
  test_recordTypeDeclarations() async {
    await assertDiagnostics(r'''
const R = (x: 1);
''', [
      lint(6, 1),
    ]);
  }

  test_recordTypeDeclarations_ok() async {
    await assertNoDiagnostics(r'''
const r = (x: 1);
''');
  }
}
