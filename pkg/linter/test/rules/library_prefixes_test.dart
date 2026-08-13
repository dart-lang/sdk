// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryPrefixesTest);
  });
}

@reflectiveTest
class LibraryPrefixesTest extends LintRuleTest {
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    diag.unusedImport,
    diag.unusedLocalVariable,
  ];

  @override
  String get lintRule => LintNames.library_prefixes;

  test_camelCase() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async' as [!dartAsync!];
''');
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
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async' as [!_1!];
''');
  }

  test_wildcard() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as _;
''');
  }

  test_wildcard_preWildCards() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.4
// (pre wildcard-variables)

import 'dart:async' as [!_!];
''');
  }
}
