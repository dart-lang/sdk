// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantIdentifierNamesTest);
  });
}

@reflectiveTest
class NonConstantIdentifierNamesTest extends LintRuleTest {
  @override
  String get lintRule => 'non_constant_identifier_names';

  ///https://github.com/dart-lang/linter/issues/193
  test_ignoreSyntheticNodes() async {
    await assertDiagnostics(r'''
class C <E>{ }
C<int>;
''', [
      // No lint
      error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 15, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 15, 1),
      error(ParserErrorCode.MISSING_FUNCTION_BODY, 21, 1),
    ]);
  }
}
