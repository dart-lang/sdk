// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantIdentifierNamesTest);
  });
}

@reflectiveTest
class ConstantIdentifierNamesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.constant_identifier_names;

  test_augmentationEnum() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum E {
  a;
}
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

augment enum E {
  [!Xy!];
}
''');
  }

  test_augmentationTopLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

const [!PI!] = 3.14;
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/56174',
    reason: 'There are unexpected diagnostics.',
  )
  // TODO(scheglov): implement augmentation
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

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/56174',
    reason: 'There are unexpected diagnostics.',
  )
  // TODO(scheglov): implement augmentation
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
    await assertDiagnosticsFromMarkup(r'''
class A {
  static const [!AA!] = (1, );
}
''');
  }

  test_destructuredConstVariable() async {
    await assertDiagnosticsFromMarkup(r'''
const [!AA!] = (1, );
''');
  }

  test_destructuredFinalVariable() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  final ([!AA!], ) = (1, );
}
''');
  }

  test_destructuredObjectField_switch() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  var a;
}

f(A a) {
  switch (a) {
    case A(a: int /*[0*/a_b/*0]*/):
  }
  switch (a) {
    case A(a: int /*[1*/a_b/*1]*/?):
    case A(a: int /*[2*/a_b/*2]*/!):
  }
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
enum Foo {
  bar,
  [!Baz!],
}
''');
  }

  test_recordFieldDestructured() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case (x: int [!x_x!], z: int z)) { }
}
''');
  }

  test_recordFieldDestructured_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case (x_y: int x, z: int z)) { }
}
''');
  }

  test_recordTypeDeclarations() async {
    await assertDiagnosticsFromMarkup(r'''
const [!RR!] = (x: 1);
''');
  }

  test_recordTypeDeclarations_ok() async {
    await assertNoDiagnostics(r'''
const r = (x: 1);
''');
  }

  test_staticField_allCaps() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static const [!DEBUG!] = false;
}
''');
  }

  test_topLevel_allCaps() async {
    await assertDiagnosticsFromMarkup(r'''
const [!PI!] = 3.14;
''');
  }

  test_topLevel_screamingSnake() async {
    await assertDiagnosticsFromMarkup(r'''
const [!CCC_CCC!] = 1000;
''');
  }
}
