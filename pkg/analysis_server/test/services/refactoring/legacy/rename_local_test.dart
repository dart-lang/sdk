// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  int t^est = 0;
  [!newName!]() => 1;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage: "Duplicate function of name 'newName' in 'test.dart'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_hasLocalFunction_before() async {
    await indexTestUnit('''
void f() {
  newName() => 1;
  int t^est = 0;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage: "Duplicate function of name 'newName' in 'test.dart'.",
    );
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_after() async {
    await indexTestUnit('''
void f() {
  int t^est = 0;
  var [!newName!] = 1;
  print(newName);
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    expect(status.problems, hasLength(1));
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          "Duplicate local variable of name 'newName' at f in "
          "'test.dart'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_before() async {
    await indexTestUnit('''
void f() {
  var [!newName!] = 1;
  int t^est = 0;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          "Duplicate local variable of name 'newName' at f in "
          "'test.dart'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_forEachLoop() async {
    await indexTestUnit('''
void f() {
  int t^est = 0;
  for (var [!newName!] in []) {
    print(test);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          "Duplicate local variable of name 'newName' at f in "
          "'test.dart'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_otherBlock() async {
    await indexTestUnit('''
void f() {
  {
    var newName = 1;
  }
  {
    int t^est = 0;
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_hasLocalVariable_otherForEachLoop() async {
    await indexTestUnit('''
void f() {
  for (int newName in []) {}
  for (int te^st in []) {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void> test_checkFinalConditions_hasLocalVariable_otherForLoop() async {
    await indexTestUnit('''
void f() {
  for (int newName = 0; newName < 10; newName++) {}
  for (int t^est = 0; test < 10; test++) {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_hasLocalVariable_otherFunction() async {
    await indexTestUnit('''
void f() {
  int t^est = 0;
}
void g() {
  var newName = 1;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_hasPatternVariable_declarationStatement() async {
    await indexTestUnit('''
void f() {
  int t^est = 0;
  var ([!newName!], _) = (1, 2);
  print(newName);
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          "Duplicate local variable of name 'newName' at f in "
          "'test.dart'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_shadows_classMember() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f() {
    var t^est = 0;
    print([!newName!]);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          'Usage of field "A.newName" declared in "test.dart" '
          'will be shadowed by renamed local variable.',
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadows_classMember_assignmentTarget() async {
    await indexTestUnit('''
class A {
  int? foo;
  int? baz() => null;
  void bar() {
    var t^est = baz();
    [!foo!] = test;
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'foo';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          'Usage of field "A.foo" declared in "test.dart" '
          'will be shadowed by renamed local variable.',
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadows_classMember_patternDeclarationForParts() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f() {
    for (var (t^est, _) = (0, 1); test < 10; test++) {
      print([!newName!]);
    }
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          'Usage of field "A.newName" declared in "test.dart" '
          'will be shadowed by renamed local variable.',
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadows_classMember_patternDeclarationStatement() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f() {
    var (t^est, _) = (1, 2);
    print(test);
    print([!newName!]);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          'Usage of field "A.newName" declared in "test.dart" '
          'will be shadowed by renamed local variable.',
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadows_classMember_patternForEachLoop() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f(List<(int, int)> values) {
    for (var (t^est, _) in values) {
      print(test);
      print([!newName!]);
    }
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          'Usage of field "A.newName" declared in "test.dart" '
          'will be shadowed by renamed local variable.',
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadows_classMember_patternIfCase() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f(Object? x) {
    if (x case int t^est) {
      print(test);
      print([!newName!]);
    }
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          'Usage of field "A.newName" declared in "test.dart" '
          'will be shadowed by renamed local variable.',
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadows_classMember_patternSwitchCase() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f(Object? x) {
    switch (x) {
      case int t^est:
        print(test);
        print([!newName!]);
    }
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      .ERROR,
      expectedMessage:
          'Usage of field "A.newName" declared in "test.dart" '
          'will be shadowed by renamed local variable.',
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadows_classMemberOK_dotShorthandConstructorInvocation() async {
    await indexTestUnit('''
class A {
  A.newName();
}
void g(A a) {}
void f() {
  var t^est = 0;
  print(test);
  g(.newName());
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_shadows_classMemberOK_dotShorthandInvocation() async {
    await indexTestUnit('''
class A {
  static A newName() => A();
}
void g(A a) {}
void f() {
  var t^est = 0;
  print(test);
  g(.newName());
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_shadows_classMemberOK_dotShorthandPropertyAccess() async {
    await indexTestUnit('''
class A {
  static A get newName => A();
}
void g(A a) {}
void f() {
  var t^est = 0;
  print(test);
  g(.newName);
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_shadows_classMemberOK_patternDeclarationOtherBlock() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f() {
    {
      print(newName);
    }
    {
      var (t^est, _) = (1, 2);
      print(test);
    }
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_shadows_classMemberOK_qualifiedReference() async {
    await indexTestUnit('''
class A {
  var newName = 1;
  void f() {
    var t^est = 0;
    print(this.newName);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  /// The iterable of a for-each loop is evaluated outside the scope of the
  /// loop variable, so renaming can't shadow anything in it.
  Future<void>
  test_checkFinalConditions_shadows_OK_forEachLoopIterable() async {
    await indexTestUnit('''
void f(int bar) {
  for (var t^est in [bar]) {
    print(test);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'bar';
    return assertRefactoringFinalConditionsOK();
  }

  Future<void>
  test_checkFinalConditions_shadows_OK_namedParameterReference() async {
    await indexTestUnit('''
void f({newName}) {}
void g() {
  var t^est = 0;
  f(newName: test);
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringFinalConditionsOK();
  }

  Future<void> test_checkFinalConditions_shadows_parameter_forEachLoop() async {
    await indexTestUnit('''
void f(int bar) {
  for (var te^st in []) {
    f([!bar!]);
    f(test);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'bar';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, .ERROR, rangeIndex: 0);
  }

  Future<void> test_checkFinalConditions_shadows_topLevelFunction() async {
    await indexTestUnit('''
newName() {}
void f() {
  var t^est = 0;
  [!newName!](); // ref
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, .ERROR, rangeIndex: 0);
  }

  Future<void> test_checkNewName_FunctionElement() async {
    await indexTestUnit('''
void f() {
  int t^est() => 0;
}
''');
    createRenameRefactoring();
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      .FATAL,
      expectedMessage: 'Function name must not be empty.',
    );
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_LocalVariableElement() async {
    await indexTestUnit('''
void f() {
  int t^est = 0;
}
''');
    createRenameRefactoring();
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      .FATAL,
      expectedMessage: 'Variable name must not be empty.',
    );
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_localFunction() async {
    await indexTestUnit('''
void f() {
  int t^est() => 0;
  print(test);
  print(test());
}
''');
    // configure refactoring
    createRenameRefactoring();
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
    int t^est() => 1;
    print(test);
  }
  {
    int test() => 2;
    print(test);
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  int t^est = 0;
  test = 1;
  test += 2;
  print(test);
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  [for (final v^alue in values) value * 2];
}
''');
    // configure refactoring
    createRenameRefactoring();
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
Object f() => [for (final v^alue in []) value * 2];
''');
    // configure refactoring
    createRenameRefactoring();
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
final a = [for (final v^alue in []) value * 2];
''');
    // configure refactoring
    createRenameRefactoring();
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
  for (final v^alue in values) {
    value;
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
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
    int t^est = 1;
    print(test);
  }
  {
    int test = 2;
    print(test);
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  var (t^est, _) = (1, 2);
  test;
  test = 1;
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  if (x case int t^est) {
    test;
    test = 1;
    test += 2;
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  if (x case int test || [int t^est] when test > 0) {
    test;
    test = 1;
    test += 2;
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
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
    s^ign;
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
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
    i^sEven;
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  (t^est, _) = (0, 1);
  test;
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  [int t^est] when test > 0 => test,
  _ => -1,
};
''');
    // configure refactoring
    createRenameRefactoring();
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
    case [int t^est] when test < 0:
      test;
      test = 1;
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  int t^est = 0;
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  final f^oo = Foo.now();
}
''');
    // configure refactoring
    createRenameRefactoring();
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
