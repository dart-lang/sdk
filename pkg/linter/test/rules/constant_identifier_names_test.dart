// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantIdentifierNamesRecordsTest);
    defineReflectiveTests(ConstantIdentifierNamesPatternsTest);
  });
}

@reflectiveTest
class ConstantIdentifierNamesPatternsTest extends LintRuleTest {
  @override
  String get lintRule => 'constant_identifier_names';

  test_destructuredConstField() async {
    await assertDiagnostics(r'''
class A {
  static const AA = (1, );
}
''', [
      lint(25, 2),
    ]);
  }

  test_destructuredConstVariable() async {
    await assertDiagnostics(r'''
const AA = (1, );
''', [
      lint(6, 2),
    ]);
  }

  test_destructuredFinalVariable() async {
    await assertDiagnostics(r'''
void f() {
  final (AA, ) = (1, );
}
''', [
      lint(20, 2),
    ]);
  }

  test_destructuredObjectField_switch() async {
    await assertDiagnostics(r'''
class A {
  var a;
}

f(A a) {
  switch (a) {
    case A(a: int a_b):
  }
  switch (a) {
    case A(a: int a_b?):
    case A(a: int a_b!):
  }
}
''', [
      lint(64, 3),
      lint(107, 3),
      lint(132, 3),
    ]);
  }

  test_destructuredObjectField_switch_ok() async {
    await assertNoDiagnostics(r'''
class A {
  var a_b;
}

f(A a) {
  switch (a) {
    case A(:var a_b):
  }
  switch (a) {
    case A(:var a_b?):
    case A(:var a_b!):
  }
}
''');
  }
}

@reflectiveTest
class ConstantIdentifierNamesRecordsTest extends LintRuleTest {
  @override
  String get lintRule => 'constant_identifier_names';

  test_recordFieldDestructured() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case (x: int x_x, z: int z)) { }
}
''', [
      lint(35, 3),
    ]);
  }

  test_recordFieldDestructured_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case (x_y: int x, z: int z)) { }
}
''');
  }

  test_recordTypeDeclarations() async {
    await assertDiagnostics(r'''
const RR = (x: 1);
''', [
      lint(6, 2),
    ]);
  }

  test_recordTypeDeclarations_ok() async {
    await assertNoDiagnostics(r'''
const r = (x: 1);
''');
  }
}
