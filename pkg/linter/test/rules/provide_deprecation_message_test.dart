// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ProvideDeprecationMessageTest);
  });
}

@reflectiveTest
class ProvideDeprecationMessageTest extends LintRuleTest {
  @override
  String get lintRule => 'provide_deprecation_message';

  test_withMessage() async {
    await assertNoDiagnostics(r'''
@Deprecated("Text.")
class C {}
''');
  }

  test_withoutMessage() async {
    await assertDiagnostics(r'''
@deprecated
class C {}
''', [
      lint(0, 11),
    ]);
  }
}
