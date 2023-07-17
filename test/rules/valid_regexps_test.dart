// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ValidRegexpsTest);
  });
}

@reflectiveTest
class ValidRegexpsTest extends LintRuleTest {
  @override
  String get lintRule => 'valid_regexps';

  test_emojis() async {
    // https://stackoverflow.com/questions/61151471/regexp-for-unicode-13-emojis
    await assertNoDiagnostics(r'''
var e = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
    unicode: true);
''');
  }

  test_interpolation() async {
    await assertNoDiagnostics(r'''
var r = '';
var s = RegExp('( $r');
''');
  }

  test_invalid() async {
    await assertDiagnostics(r'''
var s = RegExp('(');
''', [
      lint(15, 3),
    ]);
  }

  test_valid() async {
    await assertNoDiagnostics(r'''
var s = RegExp('[(]');
''');
  }
}
