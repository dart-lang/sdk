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
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Duplicate function 'newName'.",
        expectedContextSearch: 'newName() => 1');
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
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Duplicate function 'newName'.");
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
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Duplicate local variable 'newName'.",
        expectedContextSearch: 'newName = 1;');
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
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Duplicate local variable 'newName'.",
        expectedContextSearch: 'newName = 1;');
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
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: 'Usage of field "A.newName" declared in "test.dart" '
            'will be shadowed by renamed local variable.',
        expectedContextSearch: 'newName);');
  }

  Future<void>
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
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: 'Usage of field "B.newName" declared in "test.dart" '
            'will be shadowed by renamed parameter.',
        expectedContextSearch: 'newName);');
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
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedContextSearch: 'newName(); // ref');
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
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Function name must not be empty.');
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
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Variable name must not be empty.');
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_ParameterElement() async {
    await indexTestUnit('''
void f(test) {
}
''');
    createRenameRefactoringAtString('test) {');
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Parameter name must not be empty.');
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

  Future<void> test_createChange_parameter_named() async {
    await indexTestUnit('''
myFunction({required int test}) {
  test = 1;
  test += 2;
  print(test);
}
void f() {
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
myFunction({required int newName}) {
  newName = 1;
  newName += 2;
  print(newName);
}
void f() {
  myFunction(newName: 2);
}
''');
  }

  Future<void> test_createChange_parameter_named_inOtherFile() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    newFile(a, content: r'''
class A {
  A({test});
}
''');
    newFile(b, content: r'''
import 'a.dart';

void f() {
  new A(test: 2);
}
''');
    await analyzeTestPackageFiles();

    testFile = a;
    await resolveTestFile();

    createRenameRefactoringAtString('test});');
    expect(refactoring.refactoringName, 'Rename Parameter');
    refactoring.newName = 'newName';

    await assertSuccessfulRefactoring('''
class A {
  A({newName});
}
''');
    assertFileChangeResult(b, '''
import 'a.dart';

void f() {
  new A(newName: 2);
}
''');
  }

  Future<void>
      test_createChange_parameter_named_ofConstructor_genericClass() async {
    await indexTestUnit('''
class A<T> {
  A({required T test});
}

void f() {
  A(test: 0);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test}');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A<T> {
  A({required T newName});
}

void f() {
  A(newName: 0);
}
''');
  }

  Future<void> test_createChange_parameter_named_ofMethod_genericClass() async {
    await indexTestUnit('''
class A<T> {
  void foo({required T test}) {}
}

void f(A<int> a) {
  a.foo(test: 0);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test}');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A<T> {
  void foo({required T newName}) {}
}

void f(A<int> a) {
  a.foo(newName: 0);
}
''');
  }

  Future<void> test_createChange_parameter_named_updateHierarchy() async {
    await indexUnit('/home/test/lib/test2.dart', '''
library test2;
class A {
  void foo({int? test}) {
    print(test);
  }
}
class B extends A {
  void foo({int? test}) {
    print(test);
  }
}
''');
    await indexTestUnit('''
import 'test2.dart';
void f() {
  new A().foo(test: 10);
  new B().foo(test: 20);
  new C().foo(test: 30);
}
class C extends A {
  void foo({int? test}) {
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
void f() {
  new A().foo(newName: 10);
  new B().foo(newName: 20);
  new C().foo(newName: 30);
}
class C extends A {
  void foo({int? newName}) {
    print(newName);
  }
}
''');
    assertFileChangeResult('/home/test/lib/test2.dart', '''
library test2;
class A {
  void foo({int? newName}) {
    print(newName);
  }
}
class B extends A {
  void foo({int? newName}) {
    print(newName);
  }
}
''');
  }

  Future<void> test_createChange_parameter_optionalPositional() async {
    await indexTestUnit('''
myFunction([int? test]) {
  test = 1;
  test += 2;
  print(test);
}
void f() {
  myFunction(2);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test]) {');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
myFunction([int? newName]) {
  newName = 1;
  newName += 2;
  print(newName);
}
void f() {
  myFunction(2);
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
