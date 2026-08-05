// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingEnumConstantInSwitchTest);
    defineReflectiveTests(MissingEnumConstantInSwitchTest_Language219);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingEnumConstantInSwitchTest extends PubPackageResolutionTest {
  test_all_enhanced() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  one, two;

  static const x = 0;
}

void f(E e) {
  switch (e) {
    case E.one:
      break;
    case E.two:
      break;
  }
}
''');
  }

  test_default() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.one:
      break;
    default:
      break;
  }
}
''');
  }

  test_first() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.one'.
    case E.two:
    case E.three:
      break;
  }
}
''');
  }

  test_last() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.three'.
    case E.one:
    case E.two:
      break;
  }
}
''');
  }

  test_middle() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.two'.
    case E.one:
    case E.three:
      break;
  }
}
''');
  }

  test_nullable() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two }

void f(E? e) {
  switch (e) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E?' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'null'.
    case E.one:
    case E.two:
      break;
  }
}
''');
  }

  test_nullable_default() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
      break;
    default:
      break;
  }
}
''');
  }

  test_nullable_null() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
      break;
    case E.two:
      break;
    case null:
      break;
  }
}
''');
  }
}

@reflectiveTest
class MissingEnumConstantInSwitchTest_Language219
    extends PubPackageResolutionTest
    with WithLanguage219Mixin {
  test_all_enhanced() async {
    await resolveTestCodeWithDiagnostics('''
enum E {
  one, two;

  static const x = 0;
}

void f(E e) {
  switch (e) {
    case E.one:
      break;
    case E.two:
      break;
  }
}
''');
  }

  test_default() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.one:
      break;
    default:
      break;
  }
}
''');
  }

  test_first() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
//^^^^^^^^^^
// [diag.missingEnumConstantInSwitch] Missing case clause for 'one'.
    case E.two:
    case E.three:
      break;
  }
}
''');
  }

  test_last() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
//^^^^^^^^^^
// [diag.missingEnumConstantInSwitch] Missing case clause for 'three'.
    case E.one:
    case E.two:
      break;
  }
}
''');
  }

  test_middle() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
//^^^^^^^^^^
// [diag.missingEnumConstantInSwitch] Missing case clause for 'two'.
    case E.one:
    case E.three:
      break;
  }
}
''');
  }

  test_nullable() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two }

void f(E? e) {
  switch (e) {
//^^^^^^^^^^
// [diag.missingEnumConstantInSwitch] Missing case clause for 'null'.
    case E.one:
    case E.two:
      break;
  }
}
''');
  }

  test_nullable_default() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
      break;
    default:
      break;
  }
}
''');
  }

  test_nullable_null() async {
    await resolveTestCodeWithDiagnostics('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
      break;
    case E.two:
      break;
    case null:
      break;
  }
}
''');
  }

  test_parenthesized() async {
    // TODO(johnniwinther): Re-enable this test for the patterns feature.
    await resolveTestCodeWithDiagnostics('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case (E.one):
      break;
    case (E.two):
      break;
    case (E.three):
      break;
  }
}
''');
  }
}
