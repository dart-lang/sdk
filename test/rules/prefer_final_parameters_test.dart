// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalParametersTestLanguage219);
    defineReflectiveTests(PreferFinalParametersTestLanguage300);
  });
}

@reflectiveTest
class PreferFinalParametersTestLanguage219 extends LintRuleTest
    with LanguageVersion219Mixin {
  @override
  String get lintRule => 'prefer_final_parameters';

  test_superParameter() async {
    await assertDiagnostics('''
class D {
  D(final int superParameter);
}

class E extends D {
  E(super.superParameter); // OK
}
''', []);
  }

  test_superParameter_optional() async {
    await assertDiagnostics('''
class A {
  final String? a;

  A({this.a});
}

class B extends A {
  B({super.a}); // OK
}
''', []);
  }
}

@reflectiveTest
class PreferFinalParametersTestLanguage300 extends LintRuleTest
    with LanguageVersion300Mixin {
  @override
  String get lintRule => 'prefer_final_parameters';

  test_listPattern_destructured() async {
    await assertNoDiagnostics('''
void f(int p) {
  [_, p, _] = [1, 2, 3];
}
''');
  }

  test_recordPattern_destructured() async {
    await assertNoDiagnostics(r'''
void f(int a, int b) {
  (a, b) = (1, 2);
}
''');
  }
}
