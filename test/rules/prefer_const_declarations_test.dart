// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstDeclarationsTest);
  });
}

@reflectiveTest
class PreferConstDeclarationsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_const_declarations';

  test_recordLiteral() async {
    await assertDiagnostics(r'''
final tuple = const ("first", 2, true);
''', [
      lint(0, 38),
    ]);
  }

  test_test_recordLiteral_nonConst() async {
    await assertNoDiagnostics(r'''
final tuple = (1, () {});
''');
  }

  test_test_recordLiteral_ok() async {
    await assertNoDiagnostics(r'''
const record = (number: 123, name: "Main", type: "Street");
''');
  }
}
