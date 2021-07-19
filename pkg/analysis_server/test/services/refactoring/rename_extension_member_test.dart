// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameExtensionMemberTest);
  });
}

@reflectiveTest
class RenameExtensionMemberTest extends RenameRefactoringTest {
  Future<void> test_checkFinalConditions_hasMember_MethodElement() async {
    await indexTestUnit('''
extension E on int {
  test() {}
  newName() {} // existing
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Extension 'E' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  Future<void> test_checkFinalConditions_OK_dropSuffix() async {
    await indexTestUnit(r'''
extension E on int {
  void testOld() {}
}
''');
    createRenameRefactoringAtString('testOld() {}');
    // check status
    refactoring.newName = 'test';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalFunction_inExtension() async {
    await indexTestUnit('''
extension E on int {
  test() {}
  void f() {
    newName() {}
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by function 'newName'.",
      expectedContextSearch: 'test(); // marker',
    );
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalVariable_inExtension() async {
    await indexTestUnit('''
extension E on int {
  test() {}
  void f() {
    var newName;
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by local variable 'newName'.",
      expectedContextSearch: 'test(); // marker',
    );
  }

  Future<void>
      test_checkFinalConditions_shadowed_byParameter_inExtension() async {
    await indexTestUnit('''
extension E on int {
  test() {}
  void f(newName) {
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by parameter 'newName'.",
      expectedContextSearch: 'test(); // marker',
    );
  }

  Future<void> test_checkInitialConditions_operator() async {
    await indexTestUnit('''
extension E on int {
  operator -(other) => null;
}
''');
    createRenameRefactoringAtString('-(other)');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkNewName_FieldElement() async {
    await indexTestUnit('''
extension E on int {
  int get test => 0;
}
''');
    createRenameRefactoringAtString('test =>');
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Field name must not be empty.',
    );

    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_MethodElement() async {
    await indexTestUnit('''
extension E on int {
  void test() {}
}
''');
    createRenameRefactoringAtString('test() {}');

    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Method name must not be empty.',
    );

    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'The new name must be different than the current name.',
    );

    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_named_MethodElement_instance() async {
    await indexTestUnit('''
class A {}

extension E on A {
  test() {} // marker
}

void f() {
  var a = A();
  a.test();
  E(a).test();
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {} // marker');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {}

extension E on A {
  newName() {} // marker
}

void f() {
  var a = A();
  a.newName();
  E(a).newName();
}
''');
  }

  Future<void> test_createChange_named_PropertyAccessorElement_getter() async {
    await indexTestUnit('''
extension E on int {
  get test {} // marker
  set test(x) {}
  void f() {
    test;
    test = 1;
  }
}
void f() {
  0.test;
  0.test = 2;

  E(0).test;
  E(0).test = 3;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test {} // marker');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension E on int {
  get newName {} // marker
  set newName(x) {}
  void f() {
    newName;
    newName = 1;
  }
}
void f() {
  0.newName;
  0.newName = 2;

  E(0).newName;
  E(0).newName = 3;
}
''');
  }

  Future<void> test_createChange_named_PropertyAccessorElement_setter() async {
    await indexTestUnit('''
extension E on int {
  get test {}
  set test(x) {} // marker
  void f() {
    test;
    test = 1;
  }
}
void f() {
  0.test;
  0.test = 2;

  E(0).test;
  E(0).test = 3;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test(x) {} // marker');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension E on int {
  get newName {}
  set newName(x) {} // marker
  void f() {
    newName;
    newName = 1;
  }
}
void f() {
  0.newName;
  0.newName = 2;

  E(0).newName;
  E(0).newName = 3;
}
''');
  }

  Future<void> test_createChange_named_TypeParameterElement() async {
    await indexTestUnit('''
extension E<Test> on int {
  Test get g1 => throw 0;
  List<Test> get g2 => throw 0;
  Test m(Test p) => throw 0;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('Test> on int {');
    expect(refactoring.refactoringName, 'Rename Type Parameter');
    expect(refactoring.elementKindName, 'type parameter');
    expect(refactoring.oldName, 'Test');
    refactoring.newName = 'NewName';
    // validate change
    return assertSuccessfulRefactoring('''
extension E<NewName> on int {
  NewName get g1 => throw 0;
  List<NewName> get g2 => throw 0;
  NewName m(NewName p) => throw 0;
}
''');
  }

  Future<void> test_createChange_unnamed_MethodElement_instance() async {
    await indexTestUnit('''
extension on int {
  void test() {} // marker
}

void f() {
  0.test();
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {} // marker');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension on int {
  void newName() {} // marker
}

void f() {
  0.newName();
}
''');
  }
}
