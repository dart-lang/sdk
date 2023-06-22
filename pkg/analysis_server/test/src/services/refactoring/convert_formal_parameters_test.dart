// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/convert_formal_parameters.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertAllFormalParametersToNamedTest);
    defineReflectiveTests(ConvertSelectedFormalParametersToNamedTest);
  });
}

@reflectiveTest
class ConvertAllFormalParametersToNamedTest
    extends _ConvertFormalParametersToNamed {
  @override
  String get refactoringName => ConvertAllFormalParametersToNamed.commandName;

  Future<void> test_formalParameters_optionalNamed() async {
    addTestSource(r'''
void ^test({int? a}) {}

void f() {
  test(a: 0);
}
''');

    await _executeRefactoring(r'''
void test({required int? a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_formalParameters_optionalPositional() async {
    addTestSource(r'''
void ^test([int a]) {}

void f() {
  test(0);
}
''');

    await _executeRefactoring(r'''
void test({required int a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_formalParameters_requiredNamed() async {
    addTestSource(r'''
void ^test({required int? a}) {}

void f() {
  test(a: 0);
}
''');

    await _executeRefactoring(r'''
void test({required int? a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_formalParameters_requiredPositional() async {
    addTestSource(r'''
void ^test(int a) {}

void f() {
  test(0);
}
''');

    await _executeRefactoring(r'''
void test({required int a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_multiple_files() async {
    // TODO(scheglov) Unify behind `testPackageLibPath`
    addSource(getFile('$projectFolderPath/lib/a.dart').path, r'''
import 'main.dart';

void f2() {
  test(1);
}
''');

    addTestSource(r'''
void ^test(int a) {}

void f() {
  test(0);
}
''');

    // TODO(scheglov) check changes to all files.
    await _executeRefactoring(r'''
void test({required int a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_noTarget_argument() async {
    addTestSource(r'''
void test(int a) {}

void f() {
  test(42^);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_noTarget_returnType() async {
    addTestSource(r'''
^void test(int a) {}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_target_methodInvocation_name() async {
    addTestSource(r'''
void test(int a) {}

void f() {
  ^test(0);
}
''');

    await _executeRefactoring(r'''
void test({required int a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_target_topFunctionDeclaration_name() async {
    addTestSource(r'''
void ^test(int a) {}

void f() {
  test(0);
}
''');

    await _executeRefactoring(r'''
void test({required int a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> _assertNoRefactoring() async {
    await initializeServer();

    await expectNoCodeAction(
      ConvertAllFormalParametersToNamed.constTitle,
    );
  }

  Future<void> _executeRefactoring(String expected) async {
    await initializeServer();

    final codeAction = await expectCodeAction(
      ConvertAllFormalParametersToNamed.constTitle,
    );

    await executeRefactor(codeAction);

    _assertTextExpectation(content[mainFilePath]!, expected);
  }
}

@reflectiveTest
class ConvertSelectedFormalParametersToNamedTest
    extends _ConvertFormalParametersToNamed {
  @override
  String get refactoringName =>
      ConvertSelectedFormalParametersToNamed.commandName;

  Future<void> test_multiple_optionalNamed_12of4() async {
    addTestSource(r'''
void test({int a, [!int b, int c!], int d}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');

    await _executeRefactoring(r'''
void test({int a, required int b, required int c, int d}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');
  }

  Future<void> test_multiple_optionalPositional_01of2() async {
    addTestSource(r'''
void test(int a, [[!int b, int c!]]) {}

void f() {
  test(0, 1, 2);
}
''');

    await _executeRefactoring(r'''
void test(int a, {required int b, required int c}) {}

void f() {
  test(0, b: 1, c: 2);
}
''');
  }

  Future<void> test_multiple_optionalPositional_01of3() async {
    addTestSource(r'''
void test([[!int a, int b!], int c]) {}

void f() {
  test(0, 1, 2);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_multiple_requiredNamed_12of4() async {
    addTestSource(r'''
void test({
  required int a,
  [!required int b,
  required int c!],
  required int d,
}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_multiple_requiredPositional_12of4() async {
    addTestSource(r'''
void test(int a, [!int b, int c!], int d) {}

void f() {
  test(0, 1, 2, 3);
}
''');

    await _executeRefactoring(r'''
void test(int a, int d, {required int b, required int c}) {}

void f() {
  test(0, 3, b: 1, c: 2);
}
''');
  }

  Future<void> test_single_optionalNamed_0of1() async {
    addTestSource(r'''
void test(int a, {int ^b}) {}

void f() {
  test(0, b: 1);
}
''');

    await _executeRefactoring(r'''
void test(int a, {required int b}) {}

void f() {
  test(0, b: 1);
}
''');
  }

  Future<void> test_single_optionalNamed_0of2() async {
    addTestSource(r'''
void test(int a, {int ^b, int c}) {}

void f() {
  test(0, b: 1, c: 2);
}
''');

    await _executeRefactoring(r'''
void test(int a, {required int b, int c}) {}

void f() {
  test(0, b: 1, c: 2);
}
''');
  }

  Future<void> test_single_optionalPositional_0of1() async {
    addTestSource(r'''
void test(int a, [int? ^b]) {}

void f() {
  test(0, 1);
}
''');

    await _executeRefactoring(r'''
void test(int a, {required int? b}) {}

void f() {
  test(0, b: 1);
}
''');
  }

  Future<void> test_single_optionalPositional_0of2() async {
    addTestSource(r'''
void test(int a, [int? ^b, int c]) {}

void f() {
  test(0, 1, 2);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_requiredNamed() async {
    addTestSource(r'''
void test(int a, {required int ^b}) {}

void f() {
  test(0, b: 1);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_requiredPositional_0of2() async {
    addTestSource(r'''
void test(int ^a, int b) {}

void f() {
  test(0, 1);
}
''');

    await _executeRefactoring(r'''
void test(int b, {required int a}) {}

void f() {
  test(1, a: 0);
}
''');
  }

  Future<void> test_single_requiredPositional_1of2() async {
    addTestSource(r'''
void test(int a, int ^b) {}

void f() {
  test(0, 1);
}
''');

    await _executeRefactoring(r'''
void test(int a, {required int b}) {}

void f() {
  test(0, b: 1);
}
''');
  }

  Future<void> test_single_requiredPositional_1of3() async {
    addTestSource(r'''
void test(int a, int ^b, int c) {}

void f() {
  test(0, 1, 2);
}
''');

    await _executeRefactoring(r'''
void test(int a, int c, {required int b}) {}

void f() {
  test(0, 2, b: 1);
}
''');
  }

  Future<void> test_single_requiredPositional_hasNamed() async {
    addTestSource(r'''
void test(int ^a, {
  required int b,
}) {}

void f() {
  test(0, b: 1);
}
''');

    await _executeRefactoring(r'''
void test({
  required int b,
  required int a,
}) {}

void f() {
  test(b: 1, a: 0);
}
''');
  }

  Future<void> test_single_requiredPositional_hasOptionalPositional() async {
    addTestSource(r'''
void test(int ^a, [int? b]) {}

void f() {
  test(0, 1);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> _assertNoRefactoring() async {
    await initializeServer();

    await expectNoCodeAction(
      ConvertSelectedFormalParametersToNamed.constTitle,
    );
  }

  Future<void> _executeRefactoring(String expected) async {
    await initializeServer();

    final codeAction = await expectCodeAction(
      ConvertSelectedFormalParametersToNamed.constTitle,
    );

    await executeRefactor(codeAction);

    _assertTextExpectation(content[mainFilePath]!, expected);
  }
}

abstract class _ConvertFormalParametersToNamed extends RefactoringTest {
  /// TODO(scheglov) This is duplicate.
  void _assertTextExpectation(String actual, String expected) {
    if (actual != expected) {
      print('-' * 64);
      print(actual.trimRight());
      print('-' * 64);
    }
    expect(actual, expected);
  }
}
