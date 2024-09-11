// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantIdentifierNamesTest);
  });
}

@reflectiveTest
class ConstantIdentifierNamesTest extends LintRuleTest {
  @override
  String get lintRule => 'constant_identifier_names';

  test_augmentationEnum() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum E {
  a;
}
''');

    await assertDiagnostics(r'''
part of 'a.dart';

augment enum E {
  Xy;
}
''', [
      lint(38, 2),
    ]);
  }

  test_augmentationTopLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnostics(r'''
part of 'a.dart';

const PI = 3.14;
''', [
      lint(25, 2),
    ]);
  }

  test_augmentedEnumValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum E {
  Xy;
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment enum E {
  augment Xy;
}
''');
  }

  test_augmentedTopLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

const PI = 3.14;
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment const PI = 3.1415;
''');
  }

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

  test_enumValue_upperFirstLetter() async {
    await assertDiagnostics(r'''
enum Foo {
  bar,
  Baz,
}
''', [
      lint(20, 3),
    ]);
  }

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

  test_staticField_allCaps() async {
    await assertDiagnostics(r'''
class C {
  static const DEBUG = false;
}
''', [
      lint(25, 5),
    ]);
  }

  test_topLevel_allCaps() async {
    await assertDiagnostics(r'''
const PI = 3.14;
''', [
      lint(6, 2),
    ]);
  }

  test_topLevel_screamingSnake() async {
    await assertDiagnostics(r'''
const CCC_CCC = 1000;
''', [
      lint(6, 7),
    ]);
  }
}
