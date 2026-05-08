// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryConstructorNameTest);
  });
}

@reflectiveTest
class UnnecessaryConstructorNameTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_constructor_name;

  test_constructorDeclaration_named() async {
    await assertNoDiagnostics(r'''
class A {
  A.ok();
}
''');
  }

  test_constructorDeclaration_new() async {
    await assertDiagnostics(
      r'''
class A {
  A.new();
}
''',
      [lint(14, 3)],
    );
  }

  test_constructorDeclaration_new_alreadyDefined() async {
    await assertDiagnostics(
      r'''
class A {
  A();
  A.new();
}
''',
      [
        error(diag.duplicateConstructorDefault, 19, 5),
        // No lint, since we're already producing a compilation error.
      ],
    );
  }

  test_constructorTearoff_new() async {
    await assertNoDiagnostics(r'''
class A {}
var makeA = A.new;
''');
  }

  test_extensionTypeDeclaration() async {
    await assertDiagnostics(
      r'''
extension type E(int i) {
  E.new(this.i);
}
''',
      [
        // No lint.
        error(diag.duplicateConstructorDefault, 28, 5),
      ],
    );
  }

  test_extensionTypeDeclaration_primaryNamed() async {
    await assertDiagnostics(
      r'''
extension type E.a(int i) {
  E.new(this.i);
}
''',
      [lint(32, 3)],
    );
  }

  test_extensionTypeDeclaration_primaryNamedNew() async {
    await assertDiagnostics(
      r'''
extension type E.new(int i) { }
''',
      [lint(17, 3)],
    );
  }

  test_instanceCreation_named() async {
    await assertNoDiagnostics(r'''
class A {
  A.ok();
}
var aaa = A.ok();
''');
  }

  test_instanceCreation_new() async {
    await assertDiagnostics(
      r'''
class A {}
var a = A.new();
''',
      [lint(21, 3)],
    );
  }

  test_instanceCreation_unnamed() async {
    await assertNoDiagnostics(r'''
class A {}
var aa = A();
''');
  }

  test_newSyntax() async {
    await assertNoDiagnostics(r'''
class A {
  new();
}
''');
  }

  test_primaryConstructorDeclaration_new() async {
    await assertDiagnostics(
      r'''
class A.new();
''',
      [lint(8, 3)],
    );
  }
}
