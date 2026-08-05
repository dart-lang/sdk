// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:linter/src/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLeadingUnderscoresForLibraryPrefixesTest);
  });
}

@reflectiveTest
class NoLeadingUnderscoresForLibraryPrefixesTest extends LintRuleTest {
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    diag.unusedImport,
    diag.unusedLocalVariable,
  ];

  @override
  String get lintRule => LintNames.no_leading_underscores_for_library_prefixes;

  test_leadingUnderscore() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async' as [!_async!];
''');
  }

  test_notShadow_field() async {
    await assertDiagnosticsFromMarkup('''
import 'dart:async' as [!_foo!];

class C {
  int? foo;
  _foo.FutureOr<void> f() {
    print(foo);
  }
}
''', code: diag.noLeadingUnderscoresForLibraryPrefixes);
  }

  test_notShadow_noConflict() async {
    await assertDiagnosticsFromMarkup('''
import 'dart:math' as [!_foo!];

void f() {
  _foo.pi;
}
''', code: diag.noLeadingUnderscoresForLibraryPrefixes);
  }

  test_shadow_existingPrefix_namedType() async {
    await assertDiagnosticsFromMarkup('''
import 'dart:async' as [!_foo!];
import 'dart:math' as foo;

void f(_foo.FutureOr<Object> x) {}
''', code: diag.noLeadingUnderscoresForLibraryPrefixesShadowed);
  }

  test_shadow_field() async {
    await assertDiagnosticsFromMarkup('''
import 'dart:math' as [!_foo!];

class C {
  int? foo;
  void f() {
    print(foo);
    _foo.pi;
  }
}
''', code: diag.noLeadingUnderscoresForLibraryPrefixesShadowed);
  }

  test_shadow_parameter() async {
    await assertDiagnosticsFromMarkup('''
import 'dart:math' as [!_foo!];

void f(int foo) {
  _foo.pi;
}
''', code: diag.noLeadingUnderscoresForLibraryPrefixesShadowed);
  }

  test_snakeCase() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as dart_async;
''');
  }

  test_underscores() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async' as [!__!];
''');
  }

  test_wildcard() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as _;
''');
  }
}
