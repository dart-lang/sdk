// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_local;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameLocalTest);
    defineReflectiveTests(RenameLocalTest_Driver);
  });
}

@reflectiveTest
class RenameLocalTest extends RenameRefactoringTest {
  test_checkFinalConditions_hasLocalFunction_after() async {
    await indexTestUnit('''
main() {
  int test = 0;
  newName() => 1;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Duplicate function 'newName'.",
        expectedContextSearch: 'newName() => 1');
  }

  test_checkFinalConditions_hasLocalFunction_before() async {
    await indexTestUnit('''
main() {
  newName() => 1;
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Duplicate function 'newName'.");
  }

  test_checkFinalConditions_hasLocalVariable_after() async {
    await indexTestUnit('''
main() {
  int test = 0;
  var newName = 1;
  print(newName);
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    expect(status.problems, hasLength(1));
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Duplicate local variable 'newName'.",
        expectedContextSearch: 'newName = 1;');
  }

  test_checkFinalConditions_hasLocalVariable_before() async {
    await indexTestUnit('''
main() {
  var newName = 1;
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Duplicate local variable 'newName'.",
        expectedContextSearch: 'newName = 1;');
  }

  test_checkFinalConditions_hasLocalVariable_otherBlock() async {
    await indexTestUnit('''
main() {
  {
    var newName = 1;
  }
  {
    int test = 0;
  }
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  test_checkFinalConditions_hasLocalVariable_otherForEachLoop() async {
    await indexTestUnit('''
main() {
  for (int newName in []) {}
  for (int test in []) {}
}
''');
    createRenameRefactoringAtString('test in');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  test_checkFinalConditions_hasLocalVariable_otherForLoop() async {
    await indexTestUnit('''
main() {
  for (int newName = 0; newName < 10; newName++) {}
  for (int test = 0; test < 10; test++) {}
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  test_checkFinalConditions_hasLocalVariable_otherFunction() async {
    await indexTestUnit('''
main() {
  int test = 0;
}
main2() {
  var newName = 1;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  test_checkFinalConditions_shadows_classMember() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  main() {
    var test = 0;
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: 'Usage of field "A.newName" declared in "test.dart" '
            'will be shadowed by renamed local variable.',
        expectedContextSearch: 'newName);');
  }

  test_checkFinalConditions_shadows_classMember_namedParameter() async {
    await indexTestUnit('''
class A {
  foo({test: 1}) { // in A
  }
}
class B extends A {
  var newName = 1;
  foo({test: 1}) {
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test: 1}) { // in A');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: 'Usage of field "B.newName" declared in "test.dart" '
            'will be shadowed by renamed parameter.',
        expectedContextSearch: 'newName);');
  }

  test_checkFinalConditions_shadows_classMemberOK_qualifiedReference() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  main() {
    var test = 0;
    print(this.newName);
  }
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  test_checkFinalConditions_shadows_OK_namedParameterReference() async {
    await indexTestUnit('''
void f({newName}) {}
main() {
  var test = 0;
  f(newName: test);
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringFinalConditionsOK();
  }

  test_checkFinalConditions_shadows_topLevelFunction() async {
    await indexTestUnit('''
newName() {}
main() {
  var test = 0;
  newName(); // ref
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedContextSearch: 'newName(); // ref');
  }

  test_checkNewName_FunctionElement() async {
    await indexTestUnit('''
main() {
  int test() => 0;
}
''');
    createRenameRefactoringAtString('test() => 0;');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Function name must not be null.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_LocalVariableElement() async {
    await indexTestUnit('''
main() {
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0;');
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

  test_checkNewName_ParameterElement() async {
    await indexTestUnit('''
main(test) {
}
''');
    createRenameRefactoringAtString('test) {');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Parameter name must not be null.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange_localFunction() async {
    await indexTestUnit('''
main() {
  int test() => 0;
  print(test);
  print(test());
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() => 0');
    expect(refactoring.refactoringName, 'Rename Local Function');
    expect(refactoring.elementKindName, 'function');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  int newName() => 0;
  print(newName);
  print(newName());
}
''');
  }

  test_createChange_localFunction_sameNameDifferenceScopes() async {
    await indexTestUnit('''
main() {
  {
    int test() => 0;
    print(test);
  }
  {
    int test() => 1;
    print(test);
  }
  {
    int test() => 2;
    print(test);
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() => 1');
    expect(refactoring.refactoringName, 'Rename Local Function');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  {
    int test() => 0;
    print(test);
  }
  {
    int newName() => 1;
    print(newName);
  }
  {
    int test() => 2;
    print(test);
  }
}
''');
  }

  test_createChange_localVariable() async {
    await indexTestUnit('''
main() {
  int test = 0;
  test = 1;
  test += 2;
  print(test);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 0');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  int newName = 0;
  newName = 1;
  newName += 2;
  print(newName);
}
''');
  }

  test_createChange_localVariable_sameNameDifferenceScopes() async {
    await indexTestUnit('''
main() {
  {
    int test = 0;
    print(test);
  }
  {
    int test = 1;
    print(test);
  }
  {
    int test = 2;
    print(test);
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 1');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  {
    int test = 0;
    print(test);
  }
  {
    int newName = 1;
    print(newName);
  }
  {
    int test = 2;
    print(test);
  }
}
''');
  }

  test_createChange_parameter() async {
    await indexTestUnit('''
myFunction({int test}) {
  test = 1;
  test += 2;
  print(test);
}
main() {
  myFunction(test: 2);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test}) {');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
myFunction({int newName}) {
  newName = 1;
  newName += 2;
  print(newName);
}
main() {
  myFunction(newName: 2);
}
''');
  }

  test_createChange_parameter_named_inOtherFile() async {
    await indexTestUnit('''
class A {
  A({test});
}
''');
    await indexUnit(
        '/test2.dart',
        '''
import 'test.dart';
main() {
  new A(test: 2);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test});');
    expect(refactoring.refactoringName, 'Rename Parameter');
    refactoring.newName = 'newName';
    // validate change
    await assertSuccessfulRefactoring('''
class A {
  A({newName});
}
''');
    assertFileChangeResult(
        '/test2.dart',
        '''
import 'test.dart';
main() {
  new A(newName: 2);
}
''');
  }

  test_createChange_parameter_named_updateHierarchy() async {
    await indexUnit(
        '/test2.dart',
        '''
library test2;
class A {
  void foo({int test: 1}) {
    print(test);
  }
}
class B extends A {
  void foo({int test: 2}) {
    print(test);
  }
}
''');
    await indexTestUnit('''
import 'test2.dart';
main() {
  new A().foo(test: 10);
  new B().foo(test: 20);
  new C().foo(test: 30);
}
class C extends A {
  void foo({int test: 3}) {
    print(test);
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test: 20');
    expect(refactoring.refactoringName, 'Rename Parameter');
    refactoring.newName = 'newName';
    // validate change
    await assertSuccessfulRefactoring('''
import 'test2.dart';
main() {
  new A().foo(newName: 10);
  new B().foo(newName: 20);
  new C().foo(newName: 30);
}
class C extends A {
  void foo({int newName: 3}) {
    print(newName);
  }
}
''');
    assertFileChangeResult(
        '/test2.dart',
        '''
library test2;
class A {
  void foo({int newName: 1}) {
    print(newName);
  }
}
class B extends A {
  void foo({int newName: 2}) {
    print(newName);
  }
}
''');
  }

  test_oldName() async {
    await indexTestUnit('''
main() {
  int test = 0;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 0');
    // old name
    expect(refactoring.oldName, 'test');
  }
}

@reflectiveTest
class RenameLocalTest_Driver extends RenameLocalTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
