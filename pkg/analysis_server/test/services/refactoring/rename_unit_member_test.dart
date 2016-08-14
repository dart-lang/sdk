// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_unit_member;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'abstract_rename.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(RenameUnitMemberTest);
}

@reflectiveTest
class RenameUnitMemberTest extends RenameRefactoringTest {
  test_checkFinalConditions_hasTopLevel_ClassElement() async {
    indexTestUnit('''
class Test {}
class NewName {} // existing
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Library already declares class with name 'NewName'.",
        expectedContextSearch: 'NewName {} // existing');
  }

  test_checkFinalConditions_hasTopLevel_FunctionTypeAliasElement() async {
    indexTestUnit('''
class Test {}
typedef NewName(); // existing
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Library already declares function type alias with name 'NewName'.",
        expectedContextSearch: 'NewName(); // existing');
  }

  test_checkFinalConditions_OK_qualifiedSuper_MethodElement() async {
    indexTestUnit('''
class Test {}
class A {
  NewName() {}
}
class B extends A {
  main() {
    super.NewName(); // super-ref
  }
}
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  test_checkFinalConditions_publicToPrivate_usedInOtherLibrary() async {
    indexTestUnit('''
class Test {}
''');
    indexUnit(
        '/lib.dart',
        '''
library my.lib;
import 'test.dart';

main() {
  new Test();
}
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = '_NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed class will be invisible in 'my.lib'.");
  }

  test_checkFinalConditions_shadowedBy_MethodElement() async {
    indexTestUnit('''
class Test {}
class A {
  void NewName() {}
  main() {
    new Test();
  }
}
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Reference to renamed class will be shadowed by method 'A.NewName'.",
        expectedContextSearch: 'NewName() {}');
  }

  test_checkFinalConditions_shadowsInSubClass_importedLib() async {
    indexTestUnit('''
class Test {}
''');
    indexUnit(
        '/lib.dart',
        '''
library my.lib;
import 'test.dart';
class A {
  NewName() {}
}
class B extends A {
  main() {
    NewName(); // super-ref
  }",
}
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed class will shadow method 'A.NewName'.");
  }

  test_checkFinalConditions_shadowsInSubClass_importedLib_hideCombinator() async {
    indexTestUnit('''
class Test {}
''');
    indexUnit(
        '/lib.dart',
        '''
library my.lib;
import 'test.dart' hide Test;
class A {
  NewName() {}
}
class B extends A {
  main() {
    NewName(); // super-ref
  }",
}
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  test_checkFinalConditions_shadowsInSubClass_MethodElement() async {
    indexTestUnit('''
class Test {}
class A {
  NewName() {}
}
class B extends A {
  main() {
    NewName(); // super-ref
  }
}
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed class will shadow method 'A.NewName'.",
        expectedContextSearch: 'NewName(); // super-ref');
  }

  test_checkFinalConditions_shadowsInSubClass_notImportedLib() async {
    indexUnit(
        '/lib.dart',
        '''
library my.lib;
class A {
  NewName() {}
}
class B extends A {
  main() {
    NewName(); // super-ref
  }",
}
''');
    indexTestUnit('''
class Test {}
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  test_checkFinalConditions_shadowsInSubClass_notSubClass() async {
    indexTestUnit('''
class Test {}
class A {
  NewName() {}
}
class B {
  main(A a) {
    a.NewName();
  }
}
''');
    createRenameRefactoringAtString('Test {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  test_checkInitialConditions_inPubCache_posix() async {
    addSource(
        '/.pub-cache/lib.dart',
        r'''
class A {}
''');
    indexTestUnit('''
import '/.pub-cache/lib.dart';
main() {
  A a;
}
''');
    createRenameRefactoringAtString('A a');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The class 'A' is defined in a pub package, so cannot be renamed.");
  }

  test_checkInitialConditions_inPubCache_windows() async {
    addSource(
        '/Pub/Cache/lib.dart',
        r'''
class A {}
''');
    indexTestUnit('''
import '/Pub/Cache/lib.dart';
main() {
  A a;
}
''');
    createRenameRefactoringAtString('A a');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The class 'A' is defined in a pub package, so cannot be renamed.");
  }

  test_checkInitialConditions_inSDK() async {
    indexTestUnit('''
main() {
  String s;
}
''');
    createRenameRefactoringAtString('String s');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The class 'String' is defined in the SDK, so cannot be renamed.");
  }

  test_checkNewName_ClassElement() {
    indexTestUnit('''
class Test {}
''');
    createRenameRefactoringAtString('Test {}');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Class name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Class name must not be empty.");
    // same
    refactoring.newName = 'Test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The new name must be different than the current name.");
    // OK
    refactoring.newName = 'NewName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_FunctionElement() {
    indexTestUnit('''
test() {}
''');
    createRenameRefactoringAtString('test() {}');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Function name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Function name must not be empty.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_FunctionTypeAliasElement() {
    indexTestUnit('''
typedef Test();
''');
    createRenameRefactoringAtString('Test();');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Function type alias name must not be null.");
    // OK
    refactoring.newName = 'NewName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_TopLevelVariableElement() {
    indexTestUnit('''
var test;
''');
    createRenameRefactoringAtString('test;');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Variable name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Variable name must not be empty.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange_ClassElement() {
    indexTestUnit('''
class Test implements Other {
  Test() {}
  Test.named() {}
}
class Other {
  factory Other.a() = Test;
  factory Other.b() = Test.named;
}
main() {
  Test t1 = new Test();
  Test t2 = new Test.named();
}
''');
    // configure refactoring
    createRenameRefactoringAtString('Test implements');
    expect(refactoring.refactoringName, 'Rename Class');
    expect(refactoring.elementKindName, 'class');
    expect(refactoring.oldName, 'Test');
    refactoring.newName = 'NewName';
    // validate change
    return assertSuccessfulRefactoring('''
class NewName implements Other {
  NewName() {}
  NewName.named() {}
}
class Other {
  factory Other.a() = NewName;
  factory Other.b() = NewName.named;
}
main() {
  NewName t1 = new NewName();
  NewName t2 = new NewName.named();
}
''');
  }

  test_createChange_ClassElement_invocation() {
    verifyNoTestUnitErrors = false;
    indexTestUnit('''
class Test {
}
main() {
  Test(); // invalid code, but still a reference
}
''');
    // configure refactoring
    createRenameRefactoringAtString('Test();');
    expect(refactoring.refactoringName, 'Rename Class');
    expect(refactoring.elementKindName, 'class');
    expect(refactoring.oldName, 'Test');
    refactoring.newName = 'NewName';
    // validate change
    return assertSuccessfulRefactoring('''
class NewName {
}
main() {
  NewName(); // invalid code, but still a reference
}
''');
  }

  test_createChange_ClassElement_parameterTypeNested() {
    indexTestUnit('''
class Test {
}
main(f(Test p)) {
}
''');
    // configure refactoring
    createRenameRefactoringAtString('Test {');
    expect(refactoring.refactoringName, 'Rename Class');
    expect(refactoring.oldName, 'Test');
    refactoring.newName = 'NewName';
    // validate change
    return assertSuccessfulRefactoring('''
class NewName {
}
main(f(NewName p)) {
}
''');
  }

  test_createChange_ClassElement_typeAlias() {
    indexTestUnit('''
class A {}
class Test = Object with A;
main(Test t) {
}
''');
    // configure refactoring
    createRenameRefactoringAtString('Test =');
    expect(refactoring.refactoringName, 'Rename Class');
    expect(refactoring.elementKindName, 'class');
    expect(refactoring.oldName, 'Test');
    refactoring.newName = 'NewName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {}
class NewName = Object with A;
main(NewName t) {
}
''');
  }

  test_createChange_FunctionElement() {
    indexTestUnit('''
test() {}
foo() {}
main() {
  print(test);
  print(test());
  foo();
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {}');
    expect(refactoring.refactoringName, 'Rename Top-Level Function');
    expect(refactoring.elementKindName, 'function');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
newName() {}
foo() {}
main() {
  print(newName);
  print(newName());
  foo();
}
''');
  }

  test_createChange_FunctionElement_imported() async {
    indexUnit(
        '/foo.dart',
        r'''
test() {}
foo() {}
''');
    indexTestUnit('''
import 'foo.dart';
main() {
  print(test);
  print(test());
  foo();
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test);');
    expect(refactoring.refactoringName, 'Rename Top-Level Function');
    expect(refactoring.elementKindName, 'function');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    await assertSuccessfulRefactoring('''
import 'foo.dart';
main() {
  print(newName);
  print(newName());
  foo();
}
''');
    assertFileChangeResult(
        '/foo.dart',
        '''
newName() {}
foo() {}
''');
  }

  test_createChange_PropertyAccessorElement_getter_declaration() {
    return _test_createChange_PropertyAccessorElement("test {}");
  }

  test_createChange_PropertyAccessorElement_getter_usage() {
    return _test_createChange_PropertyAccessorElement("test);");
  }

  test_createChange_PropertyAccessorElement_mix() {
    return _test_createChange_PropertyAccessorElement("test += 2");
  }

  test_createChange_PropertyAccessorElement_setter_declaration() {
    return _test_createChange_PropertyAccessorElement("test(x) {}");
  }

  test_createChange_PropertyAccessorElement_setter_usage() {
    return _test_createChange_PropertyAccessorElement("test = 1");
  }

  test_createChange_TopLevelVariableElement_field() {
    return _test_createChange_TopLevelVariableElement("test = 0");
  }

  test_createChange_TopLevelVariableElement_getter() {
    return _test_createChange_TopLevelVariableElement("test);");
  }

  test_createChange_TopLevelVariableElement_mix() {
    return _test_createChange_TopLevelVariableElement("test += 2");
  }

  test_createChange_TopLevelVariableElement_setter() {
    return _test_createChange_TopLevelVariableElement("test = 1");
  }

  _test_createChange_PropertyAccessorElement(String search) {
    indexTestUnit('''
get test {}
set test(x) {}
main() {
  print(test);
  test = 1;
  test += 2;
}
''');
    // configure refactoring
    createRenameRefactoringAtString(search);
    expect(refactoring.refactoringName, 'Rename Top-Level Variable');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
get newName {}
set newName(x) {}
main() {
  print(newName);
  newName = 1;
  newName += 2;
}
''');
  }

  _test_createChange_TopLevelVariableElement(String search) {
    indexTestUnit('''
int test = 0;
main() {
  print(test);
  test = 1;
  test += 2;
}
''');
    // configure refactoring
    createRenameRefactoringAtString(search);
    expect(refactoring.refactoringName, 'Rename Top-Level Variable');
    expect(refactoring.elementKindName, 'top level variable');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
int newName = 0;
main() {
  print(newName);
  newName = 1;
  newName += 2;
}
''');
  }
}
