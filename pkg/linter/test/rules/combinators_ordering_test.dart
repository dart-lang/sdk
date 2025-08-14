// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CombinatorsOrderingTest);
  });
}

@reflectiveTest
class CombinatorsOrderingTest extends LintRuleTest {
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [WarningCode.unusedImport];

  @override
  String get lintRule => LintNames.combinators_ordering;

  test_hideCombinator_import_sorted() async {
    await assertNoDiagnostics(r'''
import 'dart:math' hide max, min;
''');
  }

  test_hideCombinator_import_unsorted() async {
    await assertDiagnostics(
      r'''
import 'dart:math' hide min, max;
''',
      [lint(19, 13)],
    );
  }

  test_showCombinator_export_sorted() async {
    await assertNoDiagnostics(r'''
export 'dart:math' show max, min;
''');
  }

  test_showCombinator_export_unsorted() async {
    await assertDiagnostics(
      r'''
export 'dart:math' show min, max;
''',
      [lint(19, 13)],
    );
  }

  test_showCombinator_import_sorted() async {
    await assertNoDiagnostics(r'''
import 'dart:math' show max, min;
''');
  }

  test_showCombinator_import_unsorted() async {
    await assertDiagnostics(
      r'''
import 'dart:math' show min, max;
''',
      [lint(19, 13)],
    );
  }
}
