// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameConstructorTest);
  });
}

@reflectiveTest
class RenameConstructorTest extends RenameRefactoringTest {
  test_checkInitialConditions_inSDK() async {
    await indexTestUnit('''
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

  test_checkNewName() async {
    await indexTestUnit('''
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

  test_checkNewName_hasMember_constructor() async {
    await indexTestUnit('''
class A {
  A.test() {}
  A.newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = refactoring.checkNewName();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Class 'A' already declares constructor with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  test_checkNewName_hasMember_method() async {
    await indexTestUnit('''
class A {
  A.test() {}
  newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = refactoring.checkNewName();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Class 'A' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  test_createChange_add() async {
    await indexTestUnit('''
class A {
  A() {} // marker
  factory A._() = A;
}
class B extends A {
  B() : super() {}
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
  factory A._() = A.newName;
}
class B extends A {
  B() : super.newName() {}
}
main() {
  new A.newName();
}
''');
  }

  test_createChange_add_toSynthetic() async {
    await indexTestUnit('''
class A {
}
class B extends A {
  B() : super() {}
}
main() {
  new A();
}
''');
    // configure refactoring
    _createConstructorInvocationRefactoring('new A();');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
class A {
  A.newName();
}
class B extends A {
  B() : super.newName() {}
}
main() {
  new A.newName();
}
''');
  }

  test_createChange_change() async {
    await indexTestUnit('''
class A {
  A.test() {} // marker
  factory A._() = A.test;
}
class B extends A {
  B() : super.test() {}
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
  factory A._() = A.newName;
}
class B extends A {
  B() : super.newName() {}
}
main() {
  new A.newName();
}
''');
  }

  test_createChange_remove() async {
    await indexTestUnit('''
class A {
  A.test() {} // marker
  factory A._() = A.test;
}
class B extends A {
  B() : super.test() {}
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
  factory A._() = A;
}
class B extends A {
  B() : super() {}
}
main() {
  new A();
}
''');
  }

  test_newInstance_nullElement() async {
    RenameRefactoring refactoring =
        new RenameRefactoring(searchEngine, null, null);
    expect(refactoring, isNull);
  }

  void _createConstructorDeclarationRefactoring(String search) {
    ConstructorElement element = findNodeElementAtString(
        search, (node) => node is ConstructorDeclaration);
    createRenameRefactoringForElement(element);
  }

  void _createConstructorInvocationRefactoring(String search) {
    ConstructorElement element = findNodeElementAtString(
        search, (node) => node is InstanceCreationExpression);
    createRenameRefactoringForElement(element);
  }
}
