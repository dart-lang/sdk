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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!bool.fromEnvironment!]('key');
}
''');
  }

  test_dotShorthand_fromEnvironment() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  bool x = .[!fromEnvironment!]('key');
}
''');
  }

  test_dotShorthand_hasEnvironment() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  bool x = .[!hasEnvironment!]('key');
}
''');
  }

  test_hasEnvironment() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!bool.hasEnvironment!]('key');
}
''');
  }

  test_int() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!int.fromEnvironment!]('key');
}
''');
  }

  test_string() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!String.fromEnvironment!]('key');
}
''');
  }
}
