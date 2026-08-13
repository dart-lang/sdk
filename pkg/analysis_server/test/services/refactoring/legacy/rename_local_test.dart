// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameLocalTest);
  });
}

@reflectiveTest
class RenameLocalTest extends RenameRefactoringTest {
  Future<void> test_checkFinalConditions_hasLocalFunction_after() async {
    await indexTestUnit('''
void f() {
  int test = 0;
  newName() => 1;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Duplicate function of name 'newName' in 'test.dart'.",
      expectedContextSearch: 'newName() => 1',
    );
  }

  Future<void> test_checkFinalConditions_hasLocalFunction_before() async {
    await indexTestUnit('''
void f() {
  newName() => 1;
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Duplicate function of name 'newName' in 'test.dart'.",
    );
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_after() async {
    await indexTestUnit('''
void f() {
  int test = 0;
  var newName = 1;
  print(newName);
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    expect(status.problems, hasLength(1));
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Duplicate local variable of name 'newName' at f in "
          "'test.dart'.",
      expectedContextSearch: 'newName = 1;',
    );
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_before() async {
    await indexTestUnit('''
void f() {
  var newName = 1;
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Duplicate local variable of name 'newName' at f in "
          "'test.dart'.",
      expectedContextSearch: 'newName = 1;',
    );
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_otherBlock() async {
    await indexTestUnit('''
void f() {
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

  Future<void>
  test_checkFinalConditions_hasLocalVariable_otherForEachLoop() async {
    await indexTestUnit('''
void f() {
  for (int newName in []) {}
  for (int test in []) {}
}
''');
    createRenameRefactoringAtString('test in');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_otherForLoop() async {
    await indexTestUnit('''
void f() {
  for (int newName = 0; newName < 10; newName++) {}
  for (int test = 0; test < 10; test++) {}
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_hasLocalVariable_otherFunction() async {
    await indexTestUnit('''
void f() {
  int test = 0;
}
void g() {
  var newName = 1;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void> test_checkFinalConditions_shadows_classMember() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f() {
    var test = 0;
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          'Usage of field "A.newName" declared in "test.dart" '
          'will be shadowed by renamed local variable.',
      expectedContextSearch: 'newName);',
    );
  }

  Future<void>
  test_checkFinalConditions_shadows_classMemberOK_qualifiedReference() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f() {
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

  Future<void>
  test_checkFinalConditions_shadows_OK_namedParameterReference() async {
    await indexTestUnit('''
void f({newName}) {}
void g() {
  var test = 0;
  f(newName: test);
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringFinalConditionsOK();
  }

  Future<void> test_checkFinalConditions_shadows_topLevelFunction() async {
    await indexTestUnit('''
newName() {}
void f() {
  var test = 0;
  newName(); // ref
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedContextSearch: 'newName(); // ref',
    );
  }

  Future<void> test_checkNewName_FunctionElement() async {
    await indexTestUnit('''
void f() {
  int test() => 0;
}
''');
    createRenameRefactoringAtString('test() => 0;');
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Function name must not be empty.',
    );
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_LocalVariableElement() async {
    await indexTestUnit('''
void f() {
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0;');
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Variable name must not be empty.',
    );
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_localFunction() async {
    await indexTestUnit('''
void f() {
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
void f() {
  int newName() => 0;
  print(newName);
  print(newName());
}
''');
  }

  Future<void>
  test_createChange_localFunction_sameNameDifferenceScopes() async {
    await indexTestUnit('''
void f() {
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
void f() {
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

  Future<void> test_createChange_localVariable() async {
    await indexTestUnit('''
void f() {
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
void f() {
  int newName = 0;
  newName = 1;
  newName += 2;
  print(newName);
}
''');
  }

  Future<void> test_createChange_localVariable_forEach_element() async {
    await indexTestUnit('''
void f(List<int> values) {
  [for (final value in values) value * 2];
}
''');
    // configure refactoring
    createRenameRefactoringAtString('value in');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(List<int> values) {
  [for (final newName in values) newName * 2];
}
''');
  }

  Future<void>
  test_createChange_localVariable_forEach_element_expressionBody() async {
    await indexTestUnit('''
Object f() => [for (final value in []) value * 2];
''');
    // configure refactoring
    createRenameRefactoringAtString('value in');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
Object f() => [for (final newName in []) newName * 2];
''');
  }

  Future<void>
  test_createChange_localVariable_forEach_element_inTopLevel() async {
    await indexTestUnit('''
final a = [for (final value in []) value * 2];
''');
    // configure refactoring
    createRenameRefactoringAtString('value in');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
final a = [for (final newName in []) newName * 2];
''');
  }

  Future<void> test_createChange_localVariable_forEach_statement() async {
    await indexTestUnit('''
void f(List<int> values) {
  for (final value in values) {
    value;
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('value in');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(List<int> values) {
  for (final newName in values) {
    newName;
  }
}
''');
  }

  Future<void>
  test_createChange_localVariable_sameNameDifferenceScopes() async {
    await indexTestUnit('''
void f() {
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
void f() {
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

  Future<void> test_createChange_patternVariable_declarationStatement() async {
    await indexTestUnit('''
void f(Object? x) {
  var (test, _) = (1, 2);
  test;
  test = 1;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test,');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(Object? x) {
  var (newName, _) = (1, 2);
  newName;
  newName = 1;
}
''');
  }

  Future<void>
  test_createChange_patternVariable_forElement_expressionFunctionBody() async {
    await indexTestUnit('''
List<int> foo(Map<int, String> map) => [
  for (var MapEntry(:key) in map.entries)
    k^ey,
];
''');
    // configure refactoring
    createRenameRefactoring();
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
List<int> foo(Map<int, String> map) => [
  for (var MapEntry(key:newName) in map.entries)
    newName,
];
''');
  }

  Future<void> test_createChange_patternVariable_ifCase() async {
    await indexTestUnit('''
void f(Object? x) {
  if (x case int test) {
    test;
    test = 1;
    test += 2;
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test) {');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(Object? x) {
  if (x case int newName) {
    newName;
    newName = 1;
    newName += 2;
  }
}
''');
  }

  Future<void> test_createChange_patternVariable_ifCase_logicalOr() async {
    await indexTestUnit('''
void f(Object? x) {
  if (x case int test || [int test] when test > 0) {
    test;
    test = 1;
    test += 2;
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test]');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(Object? x) {
  if (x case int newName || [int newName] when newName > 0) {
    newName;
    newName = 1;
    newName += 2;
  }
}
''');
  }

  Future<void>
  test_createChange_patternVariable_ifCase_patternField_explicitName() async {
    await indexTestUnit('''
void f(Object? x) {
  if (x case int(sign: var sign)) {
    sign;
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('sign;');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(Object? x) {
  if (x case int(sign: var newName)) {
    newName;
  }
}
''');
  }

  Future<void>
  test_createChange_patternVariable_ifCase_patternField_implicitName() async {
    await indexTestUnit('''
void f(Object? x) {
  if (x case int(: var isEven)) {
    isEven;
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('isEven;');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(Object? x) {
  if (x case int(isEven: var newName)) {
    newName;
  }
}
''');
  }

  Future<void> test_createChange_patternVariable_patternAssignment() async {
    await indexTestUnit('''
void f() {
  int test;
  (test, _) = (0, 1);
  test;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test,');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f() {
  int newName;
  (newName, _) = (0, 1);
  newName;
}
''');
  }

  Future<void> test_createChange_patternVariable_switchExpression() async {
    await indexTestUnit('''
Object f(Object? x) => switch (x) {
  [int test] when test > 0 => test,
  _ => -1,
};
''');
    // configure refactoring
    createRenameRefactoringAtString('test]');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
Object f(Object? x) => switch (x) {
  [int newName] when newName > 0 => newName,
  _ => -1,
};
''');
  }

  Future<void>
  test_createChange_patternVariable_switchStatement_shared() async {
    await indexTestUnit('''
void f(Object? x) {
  switch (x) {
    case int test when test > 0:
    case [int test] when test < 0:
      test;
      test = 1;
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test]');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    expect(refactoring.elementKindName, 'local variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(Object? x) {
  switch (x) {
    case int newName when newName > 0:
    case [int newName] when newName < 0:
      newName;
      newName = 1;
  }
}
''');
  }

  Future<void> test_oldName() async {
    await indexTestUnit('''
void f() {
  int test = 0;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 0');
    // old name
    expect(refactoring.oldName, 'test');
  }

  Future<void> test_reuseNameOfCalledConstructor() async {
    // https://github.com/dart-lang/sdk/issues/45105
    await indexTestUnit('''
class Foo {
  Foo.now();
}

test() {
  final foo = Foo.now();
}
''');
    // configure refactoring
    createRenameRefactoringAtString('foo =');
    refactoring.newName = 'now';
    // validate change
    return assertSuccessfulRefactoring('''
class Foo {
  Foo.now();
}

test() {
  final now = Foo.now();
}
''');
  }
}
