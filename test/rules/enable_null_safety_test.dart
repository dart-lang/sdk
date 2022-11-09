// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnableNullSafetyTest);
  });
}

@reflectiveTest
class EnableNullSafetyTest extends LintRuleTest {
  @override
  String get lintRule => 'enable_null_safety';

  test_2_11() async {
    await assertDiagnostics(r'''
// @dart=2.11
f() {
}
''', [
      lint(0, 13),
    ]);
  }

  test_2_12() async {
    await assertNoDiagnostics(r'''
// @dart=2.12
f() {
}
''');
  }

  test_2_8() async {
    await assertDiagnostics(r'''
// @dart=2.8
f() {
}
''', [
      lint(0, 12),
    ]);
  }

  test_2_8_shebang() async {
    await assertDiagnostics(r'''
#!/usr/bin/dart
// @dart=2.8
f() {
}
''', [
      lint(16, 12),
    ]);
  }
}
