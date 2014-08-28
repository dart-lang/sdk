// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_constructor;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:unittest/unittest.dart';

import 'abstract_rename.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(RenameConstructorTest);
}


@ReflectiveTestCase()
class RenameConstructorTest extends RenameRefactoringTest {
  test_checkFinalConditions_hasMember_constructor() {
    indexTestUnit('''
class A {
  A.test() {}
  A.newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test() {}');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Class 'A' already declares constructor with name 'newName'.",
          expectedContextSearch: 'newName() {} // existing');
    });
  }

  test_checkFinalConditions_hasMember_method() {
    indexTestUnit('''
class A {
  A.test() {}
  newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test() {}');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Class 'A' already declares method with name 'newName'.",
          expectedContextSearch: 'newName() {} // existing');
    });
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
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Constructor name must not be null.");
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "The new name must be different than the current name.");
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

  void _createConstructorDeclarationRefactoring(String search) {
    ConstructorElement element =
        findNodeElementAtString(search, (node) => node is ConstructorDeclaration);
    createRenameRefactoringForElement(element);
  }
}
