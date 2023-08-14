// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/convert_all_formal_parameters_to_named.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertAllFormalParametersToNamedTest);
  });
}

@reflectiveTest
class ConvertAllFormalParametersToNamedTest extends RefactoringTest {
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
    final a = getFile('$projectFolderPath/lib/a.dart');
    addSource(a.path, r'''
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

    await _executeRefactoring(r'''
void test({required int a}) {}

void f() {
  test(a: 0);
}
''');

    // TODO(scheglov) Ask me, if you want more of this opinion.
    // This is bad code.
    // I don't like using content for verifying refactoring results.
    // We need to check all changes, without a way to check only some portion.
    // See how _writeSourceChangeToBuffer is done.
    //
    // And addSource() above is another hack that we rely on to support these
    // checks here.
    // I don't like these too.
    // We have newFile() already, this should be enough.
    // Don't invent more way to add files.
    // I worked hard in DAS legacy tests to get away from it.
    // Don't add them back.
    assertTextExpectation(content[a.path]!, r'''
import 'main.dart';

void f2() {
  test(a: 1);
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

    assertTextExpectation(content[mainFilePath]!, expected);
  }
}
