// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferVoidToNullTestLanguage300);
  });
}

@reflectiveTest
class PreferVoidToNullTestLanguage300 extends LintRuleTest
    with LanguageVersion300Mixin {
  @override
  String get lintRule => 'prefer_void_to_null';

  /// https://github.com/dart-lang/linter/issues/4201
  test_castPattern() async {
    await assertDiagnostics(r'''
void f(int a) {
  switch (a) {
    case var _ as void:
  }
  a as void;
}
''', [
      // No lint.
      error(WarningCode.UNNECESSARY_CAST_PATTERN, 46, 2),
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 49, 4),
      error(HintCode.UNNECESSARY_CAST, 61, 9),
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 66, 4),
    ]);
  }
}
