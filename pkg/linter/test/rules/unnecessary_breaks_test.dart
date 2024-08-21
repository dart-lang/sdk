// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryBreaksTest);
  });
}

@reflectiveTest
class UnnecessaryBreaksTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_breaks';

  test_default() async {
    await assertDiagnostics(r'''
f() {
  switch (1) {
    case 1:
      f();
    default:
      f();
      break;
  }
}
''', [
      lint(74, 6),
    ]);
  }

  test_default_empty() async {
    // We allow the body of a `case` clause to be just a single `break;`,
    // because that's necessary to prevent the clause from being grouped with
    // the clause that follows it.
    //
    // For a `default` clause, that's not necessary, because the `default`
    // clause is required to come last. But we allow just a single `break;`
    // anyway, for consistency.
    await assertNoDiagnostics(r'''
f() {
  switch (1) {
    case 2:
      f();
    default:
      break;
  }
}
''');
  }

  test_default_notLast_ok() async {
    // No lint is needed because there is already a DEAD_CODE warning.
    await assertDiagnostics(r'''
f(bool c) {
  switch (1) {
    case 1:
      f(true);
    default:
      break;
      f(true);
  }
}
''', [
      // No lint.
      error(WarningCode.DEAD_CODE, 86, 8),
    ]);
  }

  test_switch_pre30_default_ok() async {
    await assertNoDiagnostics(r'''
// @dart=2.19
f() {
  switch (1) {
    default:
      f();
      break;
  }
}
''');
  }

  test_switch_pre30_ok() async {
    await assertNoDiagnostics(r'''
// @dart=2.19
f() {
  switch (1) {
    case 1:
      f();
      break;
  }
}
''');
  }

  test_switchPatternCase() async {
    await assertDiagnostics(r'''
f() {
  switch (1) {
    case 1:
      f();
      break;
    case 2:
      f();
  }
}
''', [
      lint(50, 6),
    ]);
  }

  test_switchPatternCase_default_ok() async {
    await assertNoDiagnostics(r'''
f(bool c) {
  switch (1) {
    case 1:
      f(true);
    default:
      if (c) break;
      f(true);
  }
}
''');
  }

  test_switchPatternCase_empty_ok() async {
    await assertNoDiagnostics(r'''
f() {
  switch (1) {
    case 1:
      break;
    case 2:
      f();
  }
}
''');
  }

  test_switchPatternCase_labeled_ok() async {
    await assertNoDiagnostics(
      r'''
f() {
  l:
  switch (1) {
    case 1:
      break l;
    case 2:
      f();
  }
}
''',
    );
  }

  test_switchPatternCase_notDirectChild_ok() async {
    await assertNoDiagnostics(r'''
f(bool c) {
  switch (1) {
    case 1:
      if (c) break;
      f(true);
    case 2:
      f(true);
  }
}
''');
  }

  test_switchPatternCase_notLast_ok() async {
    await assertDiagnostics(r'''
f(bool c) {
  switch (1) {
    case 1:
      break;
      f(true);
    case 2:
      f(true);
  }
}
''', [
      // No lint.
      error(WarningCode.DEAD_CODE, 58, 8),
    ]);
  }
}
