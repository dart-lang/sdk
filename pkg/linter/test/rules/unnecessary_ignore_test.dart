// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryIgnoreTest);
    defineReflectiveTests(UnnecessaryIgnoreDisabledTest);
    defineReflectiveTests(UnnecessaryIgnoreGeneratedFileTest);
  });
}

@reflectiveTest
class UnnecessaryIgnoreDisabledTest extends LintRuleTest {
  /// This could be any lint, just NOT `unnecessary_ignore` to ensure it's
  /// not enabled in the test.
  @override
  String get lintRule => 'camel_case_types';

  test_file() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_local_variable
void f() {}
''');
  }

  test_line() async {
    await assertNoDiagnostics(r'''
// ignore: unused_local_variable
void f() {}
''');
  }
}

@reflectiveTest
class UnnecessaryIgnoreGeneratedFileTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_ignore';

  @override
  String get testFileName => 'test.g.dart';

  test_file() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_local_variable
void f() {}
''');
  }

  test_line() async {
    await assertNoDiagnostics(r'''
// ignore: unused_local_variable
void f() {}
''');
  }
}

@reflectiveTest
class UnnecessaryIgnoreTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_ignore';

  test_file() async {
    await assertDiagnostics(
      r'''
// ignore_for_file: unused_local_variable
void f() {}
''',
      [lint(20, 21)],
    );
  }

  test_file_necessaryIgnore_sharedName() async {
    // Note: the diagnostic's shared name is `invalid_null_aware_operator`, but
    // its unique name is `invalid_null_aware_operator_after_short_circuit`, so
    // this test specifically exercises the shared name of the diagnostic.
    await assertDiagnostics(r'''
// ignore_for_file: invalid_null_aware_operator
f(int? x) => x?.abs()?.isEven;
''', []);
  }

  test_file_necessaryIgnore_uniqueName() async {
    // Note: the diagnostic's shared name is `invalid_null_aware_operator`, but
    // its unique name is `invalid_null_aware_operator_after_short_circuit`, so
    // this test specifically exercises the unique name of the diagnostic.
    await assertDiagnostics(r'''
// ignore_for_file: invalid_null_aware_operator_after_short_circuit
f(int? x) => x?.abs()?.isEven;
''', []);
  }

  test_file_unrecognizedDiagnostic() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: undefined_diagnostic_code
void f() {}
''');
  }

  test_line() async {
    await assertDiagnostics(
      r'''
// ignore: unused_local_variable
void f() {}
''',
      [lint(11, 21)],
    );
  }

  test_line_necessaryIgnore_sharedName() async {
    // Note: the diagnostic's shared name is `invalid_null_aware_operator`, but
    // its unique name is `invalid_null_aware_operator_after_short_circuit`, so
    // this test specifically exercises the shared name of the diagnostic.
    await assertDiagnostics(r'''
// ignore: invalid_null_aware_operator
f(int? x) => x?.abs()?.isEven;
''', []);
  }

  test_line_necessaryIgnore_uniqueName() async {
    // Note: the diagnostic's shared name is `invalid_null_aware_operator`, but
    // its unique name is `invalid_null_aware_operator_after_short_circuit`, so
    // this test specifically exercises the unique name of the diagnostic.
    await assertDiagnostics(r'''
// ignore: invalid_null_aware_operator_after_short_circuit
f(int? x) => x?.abs()?.isEven;
''', []);
  }

  test_line_unrecognizedDiagnostic() async {
    await assertNoDiagnostics(r'''
// ignore: undefined_diagnostic_code
void f() {}
''');
  }
}
