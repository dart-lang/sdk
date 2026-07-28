// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseFunctionTypeSyntaxForParametersTest);
  });
}

@reflectiveTest
class UseFunctionTypeSyntaxForParametersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.use_function_type_syntax_for_parameters;

  test_classicSyntax() async {
    await assertDiagnosticsFromMarkup(r'''
void f1([!bool f(int e)!]) {}
''');
  }

  test_classicSyntax_declaring() async {
    await assertDiagnosticsFromMarkup(r'''
class C([!final bool x(int e)!]);
''');
  }

  test_classicSyntax_fieldFormal() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  C([!bool this.x(int e)!]);

  bool Function(int) x;
}
''');
  }

  test_functionTypeSyntax() async {
    await assertNoDiagnostics(r'''
void f2(bool Function(int e) f) {}
''');
  }

  test_functionTypeSyntax_declaring() async {
    await assertNoDiagnostics(r'''
class C(final bool Function(int) x);
''');
  }

  test_functionTypeSyntax_fieldFormal() async {
    await assertNoDiagnostics(r'''
class C {
  C(bool Function(int) this.x);

  bool Function(int) x;
}
''');
  }
}
