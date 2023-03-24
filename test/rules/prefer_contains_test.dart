// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferContainsTest);
  });
}

@reflectiveTest
class PreferContainsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_contains';

  test_argumentTypeNotAssignable() async {
    await assertDiagnostics(r'''
List<int> list = [];
condition() {
  var next;
  while ((next = list.indexOf('{')) != -1) {}
}
''', [
      // No lint
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 77, 3),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/3546
  test_secondArgNonZero() async {
    await assertNoDiagnostics(r'''
bool b = '11'.indexOf('2', 1) == -1;
''');
  }

  /// https://github.com/dart-lang/linter/issues/3546
  test_secondArgZero() async {
    await assertDiagnostics(r'''
bool b = '11'.indexOf('2', 0) == -1;
''', [
      lint(9, 26),
    ]);
  }

  test_unnecessaryCast() async {
    await assertDiagnostics(r'''
bool le3 = ([].indexOf(1) as int) > -1;
''', [
      lint(11, 27),
      error(WarningCode.UNNECESSARY_CAST, 12, 20),
    ]);
  }
}
