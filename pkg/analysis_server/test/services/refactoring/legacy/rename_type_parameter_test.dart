// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameTypeParameterTest);
  });
}

@reflectiveTest
class RenameTypeParameterTest extends RenameRefactoringTest {
  Future<void> test_checkFinalConditions_duplicateName() async {
    await indexTestUnit('''
void f<T, U>() {}
''');

    createRenameRefactoringAtString('T, U');
    _assertKindName();
    refactoring.newName = 'U';

    final status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Duplicate type parameter 'U'.",
      expectedContextSearch: 'U>()',
    );
  }

  Future<void> test_checkNewName_empty() async {
    await indexTestUnit('''
class A<T> {}
''');

    createRenameRefactoringAtString('T>');
    _assertKindName();

    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Type parameter name must not be empty.',
    );
  }

  Future<void> test_createChange_class() async {
    await indexTestUnit('''
class A<T> {
  void foo(T a) {}
}
''');

    createRenameRefactoringAtString('T> {');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
class A<U> {
  void foo(U a) {}
}
''');
  }

  Future<void> test_createChange_class2() async {
    await indexTestUnit('''
class A<T extends U, U, V extends List<U>> {}
''');

    createRenameRefactoringAtString('U, V');
    _assertKindName();
    refactoring.newName = 'Z';

    await assertSuccessfulRefactoring('''
class A<T extends Z, Z, V extends List<Z>> {}
''');
  }

  Future<void> test_createChange_class_method() async {
    await indexTestUnit('''
class A {
  void f<T>(T a) {}
}
''');

    createRenameRefactoringAtString('T>(');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
class A {
  void f<U>(U a) {}
}
''');
  }

  Future<void> test_createChange_enum() async {
    await indexTestUnit('''
enum E<T> {
  v;
  void foo(T a) {}
}
''');

    createRenameRefactoringAtString('T> {');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
enum E<U> {
  v;
  void foo(U a) {}
}
''');
  }

  Future<void> test_createChange_extension() async {
    await indexTestUnit('''
extension E<T> on int {
  void foo(T a) {}
}
''');

    createRenameRefactoringAtString('T> on');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
extension E<U> on int {
  void foo(U a) {}
}
''');
  }

  Future<void> test_createChange_functionTypeAlias() async {
    await indexTestUnit('''
typedef void F<T>(T a);
''');

    createRenameRefactoringAtString('T>(');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
typedef void F<U>(U a);
''');
  }

  Future<void> test_createChange_functionTypeFormalParameter() async {
    await indexTestUnit('''
void f(a<T>(T b)) {}
''');

    createRenameRefactoringAtString('T>(');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
void f(a<U>(U b)) {}
''');
  }

  Future<void> test_createChange_genericFunctionType() async {
    await indexTestUnit('''
void f(void Function<T>(T a) b) {}
''');

    createRenameRefactoringAtString('T>(');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
void f(void Function<U>(U a) b) {}
''');
  }

  Future<void> test_createChange_localFunction() async {
    await indexTestUnit('''
void f() {
  void g<T>(T a) {}
}
''');

    createRenameRefactoringAtString('T>(');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
void f() {
  void g<U>(U a) {}
}
''');
  }

  Future<void> test_createChange_mixin() async {
    await indexTestUnit('''
mixin M<T> {
  void foo(T a) {}
}
''');

    createRenameRefactoringAtString('T> {');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
mixin M<U> {
  void foo(U a) {}
}
''');
  }

  Future<void> test_createChange_topLevelFunction() async {
    await indexTestUnit('''
void f<T>(T a) {}
''');

    createRenameRefactoringAtString('T>(');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
void f<U>(U a) {}
''');
  }

  Future<void> test_createChange_typeAlias() async {
    await indexTestUnit('''
typedef A<T> = void Function(T);
''');

    createRenameRefactoringAtString('T> =');
    _assertKindName();
    refactoring.newName = 'U';

    await assertSuccessfulRefactoring('''
typedef A<U> = void Function(U);
''');
  }

  void _assertKindName() {
    expect(refactoring.refactoringName, 'Rename Type Parameter');
    expect(refactoring.elementKindName, 'type parameter');
  }
}
