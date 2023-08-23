// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullInIfNullOperatorsLanguage29Test);
  });
}

@reflectiveTest
class UnnecessaryNullInIfNullOperatorsLanguage29Test extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_null_in_if_null_operators';

  @override
  String get testPackageLanguageVersion => '2.9';

  test_localVariableDeclaration_noNull() async {
    await assertNoDiagnostics(r'''
void f() {
  var x = 1 ?? 1;
}
''');
  }

  test_localVariableDeclaration_nullOnLeft() async {
    await assertDiagnostics(r'''
void f() {
  var x = null ?? 1;
}
''', [
      lint(21, 9),
    ]);
  }

  test_localVariableDeclaration_nullOnRight() async {
    await assertDiagnostics(r'''
void f() {
  var x = 1 ?? null;
}
''', [
      lint(21, 9),
    ]);
  }

  test_topLevelVariableDeclaration_noNull() async {
    await assertNoDiagnostics(r'''
var x = 1 ?? 1;
''');
  }

  test_topLevelVariableDeclaration_nullOnLeft() async {
    await assertDiagnostics(r'''
var x = null ?? 1;
''', [
      lint(8, 9),
    ]);
  }

  test_topLevelVariableDeclaration_nullOnRight() async {
    await assertDiagnostics(r'''
var x = 1 ?? null;
''', [
      lint(8, 9),
    ]);
  }
}
