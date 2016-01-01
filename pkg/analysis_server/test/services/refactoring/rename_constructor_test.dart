// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_constructor;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'abstract_rename.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(RenameConstructorTest);
}

@reflectiveTest
class RenameConstructorTest extends RenameRefactoringTest {
  test_checkFinalConditions_hasMember_constructor() async {
    indexTestUnit('''
class A {
  A.test() {}
  A.newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Class 'A' already declares constructor with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  test_checkFinalConditions_hasMember_method() async {
    indexTestUnit('''
class A {
  A.test() {}
  newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Class 'A' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  test_checkInitialConditions_inSDK() async {
    indexTestUnit('''
main() {
  new String.fromCharCodes([]);
}
''');
    createRenameRefactoringAtString('fromCharCodes(');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The constructor 'String.fromCharCodes' is defined in the SDK, so cannot be renamed.");
  }

  test_checkNewName() {
    indexTestUnit('''
class A {
  A.test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    expect(refactoring.oldName, 'test');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Constructor name must not be null.");
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The new name must be different than the current name.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatusOK(refactoring.checkNewName());
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange_add() {
    indexTestUnit('''
class A {
  A() {} // marker
}
class B extends A {
  B() : super() {}
  factory B._() = A;
}
main() {
  new A();
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('() {} // marker');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
class A {
  A.newName() {} // marker
}
class B extends A {
  B() : super.newName() {}
  factory B._() = A.newName;
}
main() {
  new A.newName();
}
''');
  }

  test_createChange_change() {
    indexTestUnit('''
class A {
  A.test() {} // marker
}
class B extends A {
  B() : super.test() {}
  factory B._() = A.test;
}
main() {
  new A.test();
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('test() {} // marker');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, 'test');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
class A {
  A.newName() {} // marker
}
class B extends A {
  B() : super.newName() {}
  factory B._() = A.newName;
}
main() {
  new A.newName();
}
''');
  }

  test_createChange_remove() {
    indexTestUnit('''
class A {
  A.test() {} // marker
}
class B extends A {
  B() : super.test() {}
  factory B._() = A.test;
}
main() {
  new A.test();
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('test() {} // marker');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, 'test');
    // validate change
    refactoring.newName = '';
    return assertSuccessfulRefactoring('''
class A {
  A() {} // marker
}
class B extends A {
  B() : super() {}
  factory B._() = A;
}
main() {
  new A();
}
''');
  }

  void test_newInstance_nullElement() {
    RenameRefactoring refactoring = new RenameRefactoring(searchEngine, null);
    expect(refactoring, isNull);
  }

  void _createConstructorDeclarationRefactoring(String search) {
    ConstructorElement element = findNodeElementAtString(
        search, (node) => node is ConstructorDeclaration);
    createRenameRefactoringForElement(element);
  }
}
