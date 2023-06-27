// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferGenericFunctionTypeAliasesTest);
  });
}

@reflectiveTest
class PreferGenericFunctionTypeAliasesTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_generic_function_type_aliases';

  test_classicTypedef() async {
    await assertDiagnostics(r'''
typedef void F();
''', [
      lint(13, 1),
    ]);
  }

  test_genericFunctionType() async {
    await assertNoDiagnostics(r'''
typedef F = void Function();
''');
  }

  /// https://github.com/dart-lang/linter/issues/2777
  test_undefinedFunction() async {
    await assertDiagnostics(r'''
typedef Cb2
''', [
      // No lint
      error(ParserErrorCode.EXPECTED_TOKEN, 8, 3),
      error(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, 12, 0),
    ]);
  }
}
