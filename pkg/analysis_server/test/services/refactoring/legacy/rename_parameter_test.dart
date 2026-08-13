// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameNamedParameterTest);
    defineReflectiveTests(RenamePositionalParameterTest);
  });
}

@reflectiveTest
class RenameNamedParameterTest extends RenameRefactoringTest {
  Future<void> test_checkFinalConditions_shadows_classMember() async {
    await indexTestUnit('''
class A {
  foo({test = 1}) { // in A
  }
}
class B extends A {
  var newName = 1;
  foo({test = 1}) {
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test = 1}) { // in A');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          'Usage of field "B.newName" declared in "test.dart" '
          'will be shadowed by renamed parameter.',
      expectedContextSearch: 'newName);',
    );
  }

  Future<void> test_createChange() async {
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

  Future<void> test_createChange_anywhere() async {
    await indexTestUnit('''
myFunction(int a, int b, {required int test}) {
  test = 1;
  test += 2;
  print(test);
}
void f() {
  myFunction(0, test: 2, 1);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test}) {');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
myFunction(int a, int b, {required int newName}) {
  newName = 1;
  newName += 2;
  print(newName);
}
void f() {
  myFunction(0, newName: 2, 1);
}
''');
  }

  Future<void> test_createChange_inOtherFile() async {
    var b = convertPath('$testPackageLibPath/b.dart');

    addTestSource(r'''
class A {
  A({test});
}
''');
    newFile(b, r'''
import 'test.dart';

void f() {
  new A(test: 2);
}
''');
    await analyzeTestPackageFiles();

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
import 'test.dart';

void f() {
  new A(newName: 2);
}
''');
  }

  Future<void> test_createChange_ofConstructor_genericClass() async {
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

  Future<void> test_createChange_ofMethod_genericClass() async {
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

  Future<void> test_createChange_super() async {
    await indexTestUnit('''
class A {
  A({required int test}); // 0
}
class B extends A {
  B({required super.test});
}
class C extends B {
  C({required super.test});
}
class D extends C {
  D({required super.test});
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test}); // 0');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  A({required int newName}); // 0
}
class B extends A {
  B({required super.newName});
}
class C extends B {
  C({required super.newName});
}
class D extends C {
  D({required super.newName});
}
''');
  }

  Future<void> test_createChange_updateHierarchy() async {
    await indexUnit('$testPackageLibPath/test2.dart', '''
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
    assertFileChangeResult('$testPackageLibPath/test2.dart', '''
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
}

@reflectiveTest
class RenamePositionalParameterTest extends RenameRefactoringTest {
  Future<void> test_catchError() async {
    await indexTestUnit('''
void f() {
  try {
  } catch (e) {
    e;
  }
}
''');
    createRenameRefactoringAtString('e) {');
    refactoring.newName = 'newName';
    await assertSuccessfulRefactoring('''
void f() {
  try {
  } catch (newName) {
    newName;
  }
}
''');
  }

  Future<void> test_catchError2() async {
    await indexTestUnit('''
void f() {
  try {
  } on Exception catch (e) {
    e;
  }
}
''');
    createRenameRefactoringAtString('e) {');
    refactoring.newName = 'newName';
    await assertSuccessfulRefactoring('''
void f() {
  try {
  } on Exception catch (newName) {
    newName;
  }
}
''');
  }

  Future<void> test_catchStackTrace() async {
    await indexTestUnit('''
void f() {
  try {
  } catch (e, s) {
    e;
    s;
  }
}
''');
    createRenameRefactoringAtString('s) {');
    refactoring.newName = 'newName';
    await assertSuccessfulRefactoring('''
void f() {
  try {
  } catch (e, newName) {
    e;
    newName;
  }
}
''');
  }

  Future<void> test_catchStackTrace2() async {
    await indexTestUnit('''
void f() {
  try {
  } on Exception catch (e, s) {
    e;
    s;
  }
}
''');
    createRenameRefactoringAtString('s) {');
    refactoring.newName = 'newName';
    await assertSuccessfulRefactoring('''
void f() {
  try {
  } on Exception catch (e, newName) {
    e;
    newName;
  }
}
''');
  }

  Future<void> test_checkNewName() async {
    await indexTestUnit('''
void f(test) {
}
''');
    createRenameRefactoringAtString('test) {');
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Parameter name must not be empty.',
    );
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_closure() async {
    await indexTestUnit('''
void f(void Function(int) _) {}

void g() => f((parameter) {
  print(parameter);
});
''');
    // configure refactoring
    createRenameRefactoringAtString('parameter) {');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(void Function(int) _) {}

void g() => f((newName) {
  print(newName);
});
''');
  }

  Future<void> test_createChange_optional() async {
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

  Future<void> test_createChange_parameterParameter() async {
    await indexTestUnit('''
void f(void Function(int myParameter) f) {
}
''');
    // configure refactoring
    createRenameRefactoringAtString('myParameter');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(void Function(int newName) f) {
}
''');
  }

  Future<void> test_createChange_super() async {
    await indexTestUnit('''
class A {
  A(int test); // 0
}
class B extends A {
  B(super.test);
}
''');

    createRenameRefactoringAtString('test); // 0');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    refactoring.newName = 'newName';

    // The name of the super-formal parameter does not have to be the same.
    // So, we don't rename it.
    return assertSuccessfulRefactoring('''
class A {
  A(int newName); // 0
}
class B extends A {
  B(super.test);
}
''');
  }

  Future<void> test_dotShorthandConstructorInvocation() async {
    await indexTestUnit('''
void foo() {
  A _ = .new(va^lue: 42);
}

class A {
  A({required int value});
}
''');
    createRenameRefactoring();
    expect(refactoring.oldName, 'value');
    refactoring.newName = 'newName';
    await assertSuccessfulRefactoring('''
void foo() {
  A _ = .new(newName: 42);
}

class A {
  A({required int newName});
}
''');
  }

  Future<void> test_dotShorthandInvocation() async {
    await indexTestUnit('''
void foo() {
  A _ = .foo(va^lue: 42);
}

class A {
  A();
  static A foo({required int value}) => A();
}
''');
    createRenameRefactoring();
    expect(refactoring.oldName, 'value');
    refactoring.newName = 'newName';
    await assertSuccessfulRefactoring('''
void foo() {
  A _ = .foo(newName: 42);
}

class A {
  A();
  static A foo({required int newName}) => A();
}
''');
  }

  Future<void> test_function_shadow() async {
    await indexTestUnit('''
void function(int a) {
  int b = 0;
}
''');
    createRenameRefactoringAtString('a) {');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    expect(refactoring.oldName, 'a');
    refactoring.newName = 'b';
    var status = await refactoring.checkFinalConditions();
    return assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Duplicate local variable of name 'b' at function in "
          "'test.dart'.",
    );
  }

  Future<void> test_hierarchy_override_lint_shadow_double() async {
    createAnalysisOptionsFile(
      lints: [LintNames.avoid_renaming_method_parameters],
    );
    await indexTestUnit('''
class C {
  void m(int? a) {
    int b = 0;
  }
}

class D extends C {
  @override
  void m(int? a) {} // marker
}

class E extends C {
  @override
  void m(int? a) {
    int b = 0;
  }
}
''');
    createRenameRefactoringAtString('a) {} // marker');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    expect(refactoring.oldName, 'a');
    refactoring.newName = 'b';
    var status = await refactoring.checkFinalConditions();
    return assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          'This will also rename all related positional parameters to the same '
          "name.\nDuplicate local variable of name 'b' at E.m in 'test.dart'. "
          'And 1 more errors.',
    );
  }

  Future<void> test_subclass_override() async {
    await indexTestUnit('''
class C {
  void m(int? a) {}
}
class D extends C {
  @override
  void m(int? a) {} // marker
}
''');
    createRenameRefactoringAtString('a) {} // marker');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    expect(refactoring.oldName, 'a');
    refactoring.newName = 'b';
    return assertSuccessfulRefactoring('''
class C {
  void m(int? a) {}
}
class D extends C {
  @override
  void m(int? b) {} // marker
}
''');
  }

  Future<void> test_subclass_override_lint() async {
    createAnalysisOptionsFile(
      lints: [LintNames.avoid_renaming_method_parameters],
    );
    await indexTestUnit('''
class C {
  void m(int? a) {}
}
class D extends C {
  @override
  void m(int? a) {} // marker
}
''');
    createRenameRefactoringAtString('a) {} // marker');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    expect(refactoring.oldName, 'a');
    refactoring.newName = 'b';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.WARNING,
      expectedMessage:
          'This will also rename all related positional '
          'parameters to the same name.',
    );
    refactoringChange = await refactoring.createChange();
    assertTestChangeResult('''
class C {
  void m(int? b) {}
}
class D extends C {
  @override
  void m(int? b) {} // marker
}
''');
  }

  Future<void> test_subclass_override_lint_shadow() async {
    createAnalysisOptionsFile(
      lints: [LintNames.avoid_renaming_method_parameters],
    );
    await indexTestUnit('''
class C {
  void m(int? a) {
    int b = 0;
  }
}
class D extends C {
  @override
  void m(int? a) {} // marker
}
''');
    createRenameRefactoringAtString('a) {} // marker');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    expect(refactoring.oldName, 'a');
    refactoring.newName = 'b';
    var status = await refactoring.checkFinalConditions();
    return assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          'This will also rename all related positional parameters to the same '
          "name.\nDuplicate local variable of name 'b' at C.m in 'test.dart'.",
    );
  }

  Future<void> test_superclass_override() async {
    await indexTestUnit('''
class C {
  void m(int? a) {} // marker
}
class D extends C {
  @override
  void m(int? a) {}
}
''');
    createRenameRefactoringAtString('a) {} // marker');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    expect(refactoring.oldName, 'a');
    refactoring.newName = 'b';
    return assertSuccessfulRefactoring('''
class C {
  void m(int? b) {} // marker
}
class D extends C {
  @override
  void m(int? a) {}
}
''');
  }

  Future<void> test_superclass_override_lint() async {
    createAnalysisOptionsFile(
      lints: [LintNames.avoid_renaming_method_parameters],
    );
    await indexTestUnit('''
class C {
  void m(int? a) {} // marker
}
class D extends C {
  @override
  void m(int? a) {}
}
''');
    createRenameRefactoringAtString('a) {} // marker');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    expect(refactoring.oldName, 'a');
    refactoring.newName = 'b';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.WARNING,
      expectedMessage:
          'This will also rename all related positional parameters to the same '
          'name.',
    );
    refactoringChange = await refactoring.createChange();
    assertTestChangeResult('''
class C {
  void m(int? b) {} // marker
}
class D extends C {
  @override
  void m(int? b) {}
}
''');
  }

  Future<void> test_superclass_override_lint_shadow() async {
    createAnalysisOptionsFile(
      lints: [LintNames.avoid_renaming_method_parameters],
    );
    await indexTestUnit('''
class C {
  void m(int? a) {} // marker
}
class D extends C {
  @override
  void m(int? a) {
    int b = 0;
  }
}
''');
    createRenameRefactoringAtString('a) {} // marker');
    expect(refactoring.refactoringName, 'Rename Parameter');
    expect(refactoring.elementKindName, 'parameter');
    expect(refactoring.oldName, 'a');
    refactoring.newName = 'b';
    var status = await refactoring.checkFinalConditions();
    return assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          'This will also rename all related positional parameters to the same '
          "name.\nDuplicate local variable of name 'b' at D.m in 'test.dart'.",
    );
  }
}
