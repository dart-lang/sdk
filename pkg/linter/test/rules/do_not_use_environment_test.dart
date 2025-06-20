// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DoNotUseEnvironmentTest);
  });
}

@reflectiveTest
class DoNotUseEnvironmentTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.do_not_use_environment;
  test_bool() async {
    await assertDiagnostics(
      r'''
void f() {
  bool.fromEnvironment('key');
}
''',
      [lint(13, 20)],
    );
  }

  test_dotShorthand_fromEnvironment() async {
    await assertDiagnostics(
      r'''
void f() {
  bool x = .fromEnvironment('key');
}
''',
      [lint(23, 15)],
    );
  }

  test_dotShorthand_hasEnvironment() async {
    await assertDiagnostics(
      r'''
void f() {
  bool x = .hasEnvironment('key');
}
''',
      [lint(23, 14)],
    );
  }

  test_hasEnvironment() async {
    await assertDiagnostics(
      r'''
void f() {
  bool.hasEnvironment('key');
}
''',
      [lint(13, 19)],
    );
  }

  test_int() async {
    await assertDiagnostics(
      r'''
void f() {
  int.fromEnvironment('key');
}
''',
      [lint(13, 19)],
    );
  }

  test_string() async {
    await assertDiagnostics(
      r'''
void f() {
  String.fromEnvironment('key');
}
''',
      [lint(13, 22)],
    );
  }

  test_messageFormatting() async {
    await assertDiagnostics(
      r'''
void f() {
  bool.fromEnvironment('DEBUG');
}
''',
      [lint(13, 27, messageContains: 'bool.fromEnvironment')],
    );
  }

  test_constContext() async {
    await assertDiagnostics(
      r'''
const bool usingAppEngine = bool.hasEnvironment('APPENGINE_RUNTIME');
''',
      [lint(28, 19)],
    );
  }
}
