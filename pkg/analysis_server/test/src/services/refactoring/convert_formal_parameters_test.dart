// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/convert_formal_parameters.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertFormalParametersToNamedTest);
  });
}

@reflectiveTest
class ConvertFormalParametersToNamedTest extends RefactoringTest {
  @override
  String get refactoringName => ConvertFormalParametersToNamed.commandName;

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
      ConvertFormalParametersToNamed.constTitle,
    );
  }

  /// TODO(scheglov) This is duplicate.
  void _assertTextExpectation(String actual, String expected) {
    if (actual != expected) {
      print('-' * 64);
      print(actual.trimRight());
      print('-' * 64);
    }
    expect(actual, expected);
  }

  Future<void> _executeRefactoring(String expected) async {
    await initializeServer();

    final codeAction = await expectCodeAction(
      ConvertFormalParametersToNamed.constTitle,
    );

    await executeRefactor(codeAction);

    _assertTextExpectation(content[mainFilePath]!, expected);
  }
}
