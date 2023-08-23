// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryStatementsTest);
  });
}

@reflectiveTest
class UnnecessaryStatementsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_statements';

  /// https://github.com/dart-lang/linter/issues/4334
  test_patternAssignment_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var (a, b) = (0, 0);
  var result = (1, 2);
  (a, b) = (a + result.$1, b + result.$2);
}
''');
  }
}
