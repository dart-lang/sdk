// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLeadingUnderscoresForLibraryPrefixesTest);
  });
}

@reflectiveTest
class NoLeadingUnderscoresForLibraryPrefixesTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes =>
      [WarningCode.UNUSED_IMPORT, WarningCode.UNUSED_LOCAL_VARIABLE];

  @override
  String get lintRule => LintNames.no_leading_underscores_for_library_prefixes;

  test_leadingUnderscore() async {
    await assertDiagnostics(r'''
import 'dart:async' as _async;
''', [
      lint(23, 6),
    ]);
  }

  test_snakeCase() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as dart_async;
''');
  }

  test_underscores() async {
    await assertDiagnostics(r'''
import 'dart:async' as __;
''', [
      lint(23, 2),
    ]);
  }

  test_wildcard() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as _;
''');
  }
}
