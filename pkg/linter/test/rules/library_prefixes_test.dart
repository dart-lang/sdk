// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryPrefixesTest);
  });
}

@reflectiveTest
class LibraryPrefixesTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes =>
      [WarningCode.UNUSED_IMPORT, WarningCode.UNUSED_LOCAL_VARIABLE];

  @override
  String get lintRule => 'library_prefixes';

  test_camelCase() async {
    await assertDiagnostics(r'''
import 'dart:async' as dartAsync;
''', [
      lint(23, 9),
    ]);
  }

  test_leadingDollar() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as $async;
''');
  }

  test_leadingUnderscore() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as _async;
''');
  }

  test_leadingUnderscore_withNumbers() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as _i1;
''');
  }

  test_numberWithLeadingUnderscore() async {
    await assertDiagnostics(r'''
import 'dart:async' as _1;
''', [
      lint(23, 2),
    ]);
  }
}
