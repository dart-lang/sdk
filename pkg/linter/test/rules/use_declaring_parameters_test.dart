// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseDeclaringParametersTest);
  });
}

@reflectiveTest
class UseDeclaringParametersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.use_declaring_parameters;

  test_assignedInBody_requiredPositional() async {
    await assertDiagnosticsFromMarkdown(r'''
class C(int [!i!]) {
  int i = 0;

  this {
    this.i = i;
  }
}
''');
  }

  test_differentName_requiredPositional() async {
    await assertNoDiagnostics(r'''
class C(int i) {
  int x;

  this : x = i;
}
''');
  }

  test_fieldFormalParameter() async {
    await assertNoDiagnostics(r'''
class C(this.i) {
  int i;
}
''');
  }

  test_finalPrivateField_requiredPositional() async {
    await assertDiagnosticsFromMarkdown(r'''
class C(int [!i!]) {
  final int _i;

  this : _i = i;
}
''');
  }

  test_finalPublicField_requiredPositional() async {
    await assertDiagnosticsFromMarkdown(r'''
class C(int [!i!]) {
  final int i;

  this : i = i;
}
''');
  }

  test_nonFinalPrivateField_optionalNamed() async {
    await assertDiagnosticsFromMarkdown(r'''
class C({int [!i!] = 0}) {
  int _i;

  this : _i = i;
}
''');
  }

  test_nonFinalPrivateField_optionalPositional() async {
    await assertDiagnosticsFromMarkdown(r'''
class C([int [!i!] = 0]) {
  int _i;

  this : _i = i;
}
''');
  }

  test_nonFinalPrivateField_requiredNamed() async {
    await assertDiagnosticsFromMarkdown(r'''
class C({required int [!i!]}) {
  int _i;

  this : _i = i;
}
''');
  }

  test_nonFinalPrivateField_requiredPositional() async {
    await assertDiagnosticsFromMarkdown(r'''
class C(int [!i!]) {
  int _i;

  this : _i = i;
}
''');
  }

  test_nonFinalPublicField_optionalNamed() async {
    await assertDiagnosticsFromMarkdown(r'''
class C({int [!i!] = 0}) {
  final int i;

  this : i = i;
}
''');
  }

  test_nonFinalPublicField_optionalPositional() async {
    await assertDiagnosticsFromMarkdown(r'''
class C([int [!i!] = 0]) {
  final int i;

  this : i = i;
}
''');
  }

  test_nonFinalPublicField_requiredNamed() async {
    await assertDiagnosticsFromMarkdown(r'''
class C({required int [!i!]}) {
  final int i;

  this : i = i;
}
''');
  }

  test_nonFinalPublicField_requiredPositional() async {
    await assertDiagnosticsFromMarkdown(r'''
class C(int [!i!]) {
  final int i;

  this : i = i;
}
''');
  }

  test_notAssigned_optionalNamed() async {
    await assertNoDiagnostics(r'''
class C({int i = 0});
''');
  }

  test_notAssigned_optionalPositional() async {
    await assertNoDiagnostics(r'''
class C([int i = 0]);
''');
  }

  test_notAssigned_requiredNamed() async {
    await assertNoDiagnostics(r'''
class C({required int i});
''');
  }

  test_notAssigned_requiredPositional() async {
    await assertNoDiagnostics(r'''
class C(int i);
''');
  }

  test_superParameter() async {
    await assertNoDiagnostics(r'''
class C(super.i) extends B;

class B(var int i);
''');
  }
}
