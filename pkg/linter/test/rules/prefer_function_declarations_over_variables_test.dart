// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFunctionDeclarationsOverVariablesTest);
  });
}

@reflectiveTest
class PreferFunctionDeclarationsOverVariablesTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_function_declarations_over_variables';

  test_instanceVariable_final() async {
    await assertDiagnostics(r'''
class C {
  final f = () {};
}
''', [
      lint(18, 9),
    ]);
  }

  test_instanceVariable_public() async {
    await assertNoDiagnostics(r'''
class C {
  var f = () {};
}
''');
  }

  test_localFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  // ignore: unused_element
  g() {}
}
''');
  }

  test_localVariable() async {
    await assertDiagnostics(r'''
void f() {
  var g = () {};
}
''', [
      lint(17, 9),
    ]);
  }

  test_localVariable_nonFunctionLiteral() async {
    await assertNoDiagnostics(r'''
void f(Function fn) {
  var g = fn;
}
''');
  }

  test_localVariable_reassigned() async {
    await assertNoDiagnostics(r'''
void f() {
  var g = () {};
  g = () {};
}
''');
  }

  test_topLevelVariable_final() async {
    await assertDiagnostics(r'''
final f = () {};
''', [
      lint(6, 9),
    ]);
  }

  test_topLevelVariable_public() async {
    await assertNoDiagnostics(r'''
var f = () {};
''');
  }

  // TODO(srawlins): Add test for static fields.
  // TODO(srawlins): Add test for private top-level variables.
  // TODO(srawlins): Add test for private instance fields, instance fields on
  // private classes, mixins, enums.
  // TODO(srawlins): Add test for final instance fields without initializer,
  // assigned in constructor.
}
