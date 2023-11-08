// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/move_selected_formal_parameters_left.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveSelectedFormalParametersLeftTest);
  });
}

@reflectiveTest
class MoveSelectedFormalParametersLeftTest extends RefactoringTest {
  @override
  String get refactoringName => MoveSelectedFormalParametersLeft.commandName;

  Future<void> test_multiple_requiredNamed_first() async {
    addTestSource(r'''
void test({
[!  required int a,
  required int b,
!]  required int c,
  required int d,
}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_multiple_requiredNamed_middle() async {
    addTestSource(r'''
void test({
  required int a,
[!  required int b,
  required int c,
!]  required int d,
}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test({
  required int b,
  required int c,
  required int a,
  required int d,
}) {}

void f() {
  test(b: 1, c: 2, a: 0, d: 3);
}
''');
  }

  Future<void> test_multiple_requiredPositional_first() async {
    addTestSource(r'''
void test([!int a, int b,!] int c) {}

void f() {
  test(0, 1, 2);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_multiple_requiredPositional_middle() async {
    addTestSource(r'''
void test(int a, int b, [!int c, int d,!] int e) {}

void f() {
  test(0, 1, 2, 3, 4);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, int c, int d, int b, int e) {}

void f() {
  test(0, 2, 3, 1, 4);
}
''');
  }

  Future<void> test_multiple_requiredPositional_middle_toFirst() async {
    addTestSource(r'''
void test(int a, [!int b, int c,!] int d) {}

void f() {
  test(0, 1, 2, 3);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int b, int c, int a, int d) {}

void f() {
  test(1, 2, 0, 3);
}
''');
  }

  Future<void> test_single_optionalNamed_middle() async {
    addTestSource(r'''
void test({
  int? a,
  int? ^b,
  int? c,
}) {}

void f() {
  test(a: 0, b: 1, c: 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test({
  int? b,
  int? a,
  int? c,
}) {}

void f() {
  test(b: 1, a: 0, c: 2);
}
''');
  }

  Future<void> test_single_optionalNamed_middle_afterRequiredNamed() async {
    addTestSource(r'''
void test({
  required int? a,
  int? ^b,
  int? c,
}) {}

void f() {
  test(a: 0, b: 1, c: 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test({
  int? b,
  required int? a,
  int? c,
}) {}

void f() {
  test(b: 1, a: 0, c: 2);
}
''');
  }

  Future<void> test_single_optionalPositional_first() async {
    addTestSource(r'''
void test(int a, [int? ^b, int ?c]) {}

void f() {
  test(0, 1, 2);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_optionalPositional_middle() async {
    addTestSource(r'''
void test([int a, int ^b, int c]) {}

void f() {
  test(0, 1, 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test([int b, int a, int c]) {}

void f() {
  test(1, 0, 2);
}
''');
  }

  Future<void> test_single_requiredNamed_first_hasPositional() async {
    addTestSource(r'''
void test(
  int a, {
  required int ^b,
  required int c,
}) {}

void f() {
  test(0, b: 1, c: 2);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_requiredNamed_first_noPositional() async {
    addTestSource(r'''
void test({
  required int ^a,
  required int b,
}) {}

void f() {
  test(a: 0, b: 1);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_requiredNamed_last() async {
    addTestSource(r'''
void test({
  required int a,
  required int b,
  required int ^c,
}) {}

void f() {
  test(a: 0, b: 1, c: 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test({
  required int a,
  required int c,
  required int b,
}) {}

void f() {
  test(a: 0, c: 2, b: 1);
}
''');
  }

  Future<void> test_single_requiredNamed_middle() async {
    addTestSource(r'''
void test({
  required int a,
  required int b,
  required int ^c,
  required int d,
}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test({
  required int a,
  required int c,
  required int b,
  required int d,
}) {}

void f() {
  test(a: 0, c: 2, b: 1, d: 3);
}
''');
  }

  Future<void> test_single_requiredNamed_middle_toFirst() async {
    addTestSource(r'''
void test({
  required int a,
  required int ^b,
  required int c,
}) {}

void f() {
  test(a: 0, b: 1, c: 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test({
  required int b,
  required int a,
  required int c,
}) {}

void f() {
  test(b: 1, a: 0, c: 2);
}
''');
  }

  Future<void> test_single_requiredPositional_first() async {
    addTestSource(r'''
void test(int ^a, int b, int c) {}

void f() {
  test(0, 1, 2);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_requiredPositional_last() async {
    addTestSource(r'''
void test(int a, int b, int ^c) {}

void f() {
  test(0, 1, 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, int c, int b) {}

void f() {
  test(0, 2, 1);
}
''');
  }

  Future<void> test_single_requiredPositional_middle() async {
    addTestSource(r'''
void test(int a, int ^b, int c) {}

void f() {
  test(0, 1, 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int b, int a, int c) {}

void f() {
  test(1, 0, 2);
}
''');
  }

  Future<void> verifyRefactoring(String expected) async {
    await initializeServer();

    final codeAction = await expectCodeAction(
      MoveSelectedFormalParametersLeft.constTitle,
    );

    await verifyCommandEdits(codeAction.command!, expected);
  }

  Future<void> _assertNoRefactoring() async {
    await initializeServer();

    await expectNoCodeAction(
      MoveSelectedFormalParametersLeft.constTitle,
    );
  }
}
