// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_class_member;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameClassMemberTest);
    defineReflectiveTests(RenameClassMemberTest_Driver);
  });
}

@reflectiveTest
class RenameClassMemberTest extends RenameRefactoringTest {
  test_checkFinalConditions_classNameConflict_sameClass() async {
    await indexTestUnit('''
class NewName {
  void test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method has the same name as the declaring class 'NewName'.",
        expectedContextSearch: 'test() {}');
  }

  test_checkFinalConditions_classNameConflict_subClass() async {
    await indexTestUnit('''
class A {
  void test() {} // 1
}
class NewName extends A {
  void test() {} // 2
}
''');
    createRenameRefactoringAtString('test() {} // 1');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method has the same name as the declaring class 'NewName'.",
        expectedContextSearch: 'test() {} // 2');
  }

  test_checkFinalConditions_classNameConflict_superClass() async {
    await indexTestUnit('''
class NewName {
  void test() {} // 1
}
class B extends NewName {
  void test() {} // 2
}
''');
    createRenameRefactoringAtString('test() {} // 2');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method has the same name as the declaring class 'NewName'.",
        expectedContextSearch: 'test() {} // 1');
  }

  test_checkFinalConditions_hasMember_MethodElement() async {
    await indexTestUnit('''
class A {
  test() {}
  newName() {} // existing
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Class 'A' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  test_checkFinalConditions_OK_dropSuffix() async {
    await indexTestUnit(r'''
abstract class A {
  void testOld();
}
class B implements A {
  void testOld() {}
}
''');
    createRenameRefactoringAtString('testOld() {}');
    // check status
    refactoring.newName = 'test';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  test_checkFinalConditions_OK_noShadow() async {
    await indexTestUnit('''
class A {
  int newName;
}
class B {
  test() {}
}
class C extends A {
  main() {
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  test_checkFinalConditions_publicToPrivate_usedInOtherLibrary() async {
    await indexTestUnit('''
class A {
  test() {}
}
''');
    await indexUnit(
        '/lib.dart',
        '''
library my.lib;
import 'test.dart';

main(A a) {
  a.test();
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = '_newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will be invisible in 'my.lib'.");
  }

  test_checkFinalConditions_shadowed_byLocalFunction_inSameClass() async {
    await indexTestUnit('''
class A {
  test() {}
  main() {
    newName() {}
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by function 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  test_checkFinalConditions_shadowed_byLocalVariable_inSameClass() async {
    await indexTestUnit('''
class A {
  test() {}
  main() {
    var newName;
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by local variable 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  test_checkFinalConditions_shadowed_byLocalVariable_inSubClass() async {
    await indexTestUnit('''
class A {
  test() {}
}
class B extends A {
  main() {
    var newName;
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by local variable 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  test_checkFinalConditions_shadowed_byLocalVariable_OK_qualifiedReference() async {
    await indexTestUnit('''
class A {
  test() {}
  main() {
    var newName;
    this.test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  test_checkFinalConditions_shadowed_byLocalVariable_OK_renamedNotUsed() async {
    await indexTestUnit('''
class A {
  test() {}
  main() {
    var newName;
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  test_checkFinalConditions_shadowed_byParameter_inSameClass() async {
    await indexTestUnit('''
class A {
  test() {}
  main(newName) {
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by parameter 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  test_checkFinalConditions_shadowedBySub_MethodElement() async {
    await indexTestUnit('''
class A {
  test() {}
}
class B extends A {
  newName() {} // marker
  main() {
    test();
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method will be shadowed by method 'B.newName'.",
        expectedContextSearch: 'newName() {} // marker');
  }

  test_checkFinalConditions_shadowsSuper_FieldElement() async {
    await indexTestUnit('''
class A {
  int newName; // marker
}
class B extends A {
  test() {}
}
class C extends B {
  main() {
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will shadow field 'A.newName'.",
        expectedContextSearch: 'newName; // marker');
  }

  test_checkFinalConditions_shadowsSuper_MethodElement() async {
    await indexTestUnit('''
class A {
  newName() {} // marker
}
class B extends A {
  test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will shadow method 'A.newName'.",
        expectedContextSearch: 'newName() {} // marker');
  }

  test_checkFinalConditions_shadowsSuper_MethodElement_otherLib() async {
    var libCode = r'''
class A {
  newName() {} // marker
}
''';
    await indexUnit('/lib.dart', libCode);
    await indexTestUnit('''
import 'lib.dart';
class B extends A {
  test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will shadow method 'A.newName'.",
        expectedContextRange: new SourceRange(
            libCode.indexOf('newName() {} // marker'), 'newName'.length));
  }

  test_checkInitialConditions_inSDK() async {
    await indexTestUnit('''
main() {
  'abc'.toUpperCase();
}
''');
    createRenameRefactoringAtString('toUpperCase()');
    // check status
    refactoring.newName = 'NewName';
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The method 'String.toUpperCase' is defined in the SDK, so cannot be renamed.");
  }

  test_checkInitialConditions_operator() async {
    await indexTestUnit('''
class A {
  operator -(other) => this;
}
''');
    createRenameRefactoringAtString('-(other)');
    // check status
    refactoring.newName = 'newName';
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  test_checkNewName_FieldElement() async {
    await indexTestUnit('''
class A {
  int test;
}
''');
    createRenameRefactoringAtString('test;');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Field name must not be null.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_MethodElement() async {
    await indexTestUnit('''
class A {
  test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Method name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Method name must not be empty.");
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The new name must be different than the current name.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange_FieldElement() async {
    await indexTestUnit('''
class A {
  int test; // marker
  main() {
    print(test);
    test = 1;
    test += 2;
  }
}
class B extends A {
}
class C extends B {
  get test => 1;
  set test(x) {}
}
main() {
  A a = new A();
  B b = new B();
  C c = new C();
  print(a.test);
  a.test = 1;
  a.test += 2;
  print(b.test);
  b.test = 1;
  print(c.test);
  c.test = 1;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test; // marker');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.elementKindName, 'field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  int newName; // marker
  main() {
    print(newName);
    newName = 1;
    newName += 2;
  }
}
class B extends A {
}
class C extends B {
  get newName => 1;
  set newName(x) {}
}
main() {
  A a = new A();
  B b = new B();
  C c = new C();
  print(a.newName);
  a.newName = 1;
  a.newName += 2;
  print(b.newName);
  b.newName = 1;
  print(c.newName);
  c.newName = 1;
}
''');
  }

  test_createChange_FieldElement_constructorFieldInitializer() async {
    await indexTestUnit('''
class A {
  final test;
  A() : test = 5;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test;');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  final newName;
  A() : newName = 5;
}
''');
  }

  test_createChange_FieldElement_fieldFormalParameter() async {
    await indexTestUnit('''
class A {
  final test;
  A(this.test);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test;');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  final newName;
  A(this.newName);
}
''');
  }

  test_createChange_FieldElement_fieldFormalParameter_named() async {
    await indexTestUnit('''
class A {
  final test;
  A({this.test});
}
main() {
  new A(test: 42);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test;');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  final newName;
  A({this.newName});
}
main() {
  new A(newName: 42);
}
''');
  }

  test_createChange_FieldElement_invocation() async {
    await indexTestUnit('''
typedef F(a);
class A {
  F test;
  main() {
    test(1);
  }
}
main() {
  A a = new A();
  a.test(2);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test(2);');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
typedef F(a);
class A {
  F newName;
  main() {
    newName(1);
  }
}
main() {
  A a = new A();
  a.newName(2);
}
''');
  }

  test_createChange_MethodElement() async {
    await indexTestUnit('''
class A {
  test() {}
}
class B extends A {
  test() {} // marker
}
class C extends B {
  test() {}
}
class D implements A {
  test() {}
}
class E {
  test() {}
}
main() {
  A a = new A();
  B b = new B();
  C c = new C();
  D d = new D();
  E e = new E();
  a.test();
  b.test();
  c.test();
  d.test();
  e.test();
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
class A {
  newName() {}
}
class B extends A {
  newName() {} // marker
}
class C extends B {
  newName() {}
}
class D implements A {
  newName() {}
}
class E {
  test() {}
}
main() {
  A a = new A();
  B b = new B();
  C c = new C();
  D d = new D();
  E e = new E();
  a.newName();
  b.newName();
  c.newName();
  d.newName();
  e.test();
}
''');
  }

  test_createChange_MethodElement_potential() async {
    await indexTestUnit('''
class A {
  test() {}
}
main(var a) {
  a.test(); // 1
  new A().test();
  a.test(); // 2
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {}');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    await assertSuccessfulRefactoring('''
class A {
  newName() {}
}
main(var a) {
  a.newName(); // 1
  new A().newName();
  a.newName(); // 2
}
''');
    assertPotentialEdits(['test(); // 1', 'test(); // 2']);
  }

  test_createChange_MethodElement_potential_inPubCache() async {
    String pkgLib = '/.pub-cache/lib.dart';
    await indexUnit(
        pkgLib,
        r'''
processObj(p) {
  p.test();
}
''');
    await indexTestUnit('''
import '$pkgLib';
class A {
  test() {}
}
main(var a) {
  a.test();
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {}');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    await assertSuccessfulRefactoring('''
import '/.pub-cache/lib.dart';
class A {
  newName() {}
}
main(var a) {
  a.newName();
}
''');
    SourceFileEdit fileEdit = refactoringChange.getFileEdit(pkgLib);
    expect(fileEdit, isNull);
  }

  test_createChange_MethodElement_potential_private_otherLibrary() async {
    await indexUnit(
        '/lib.dart',
        '''
library lib;
main(p) {
  p._test();
}
''');
    await indexTestUnit('''
class A {
  _test() {}
}
main(var a) {
  a._test();
  new A()._test();
}
''');
    // configure refactoring
    createRenameRefactoringAtString('_test() {}');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.oldName, '_test');
    refactoring.newName = 'newName';
    // validate change
    await assertSuccessfulRefactoring('''
class A {
  newName() {}
}
main(var a) {
  a.newName();
  new A().newName();
}
''');
    assertNoFileChange('/lib.dart');
  }

  test_createChange_PropertyAccessorElement_getter() async {
    await indexTestUnit('''
class A {
  get test {} // marker
  set test(x) {}
  main() {
    print(test);
    test = 1;
  }
}
class B extends A {
  get test {}
  set test(x) {}
}
main() {
  A a = new A();
  print(a.test);
  a.test = 2;

  B b = new B();
  print(b.test);
  b.test = 2;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test {} // marker');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  get newName {} // marker
  set newName(x) {}
  main() {
    print(newName);
    newName = 1;
  }
}
class B extends A {
  get newName {}
  set newName(x) {}
}
main() {
  A a = new A();
  print(a.newName);
  a.newName = 2;

  B b = new B();
  print(b.newName);
  b.newName = 2;
}
''');
  }

  test_createChange_PropertyAccessorElement_setter() async {
    await indexTestUnit('''
class A {
  get test {}
  set test(x) {} // marker
  main() {
    print(test);
    test = 1;
  }
}
class B extends A {
  get test {}
  set test(x) {}
}
main() {
  A a = new A();
  print(a.test);
  a.test = 2;

  B b = new B();
  print(b.test);
  b.test = 2;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test(x) {} // marker');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  get newName {}
  set newName(x) {} // marker
  main() {
    print(newName);
    newName = 1;
  }
}
class B extends A {
  get newName {}
  set newName(x) {}
}
main() {
  A a = new A();
  print(a.newName);
  a.newName = 2;

  B b = new B();
  print(b.newName);
  b.newName = 2;
}
''');
  }

  test_createChange_TypeParameterElement() async {
    await indexTestUnit('''
class A<Test> {
  Test field;
  List<Test> items;
  Test method(Test p) => null;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('Test> {');
    expect(refactoring.refactoringName, 'Rename Type Parameter');
    expect(refactoring.elementKindName, 'type parameter');
    expect(refactoring.oldName, 'Test');
    refactoring.newName = 'NewName';
    // validate change
    return assertSuccessfulRefactoring('''
class A<NewName> {
  NewName field;
  List<NewName> items;
  NewName method(NewName p) => null;
}
''');
  }
}

@reflectiveTest
class RenameClassMemberTest_Driver extends RenameClassMemberTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  @override
  test_checkFinalConditions_shadowed_byLocalFunction_inSameClass() {
    return super
        .test_checkFinalConditions_shadowed_byLocalFunction_inSameClass();
  }

  @failingTest
  @override
  test_checkFinalConditions_shadowed_byLocalVariable_inSameClass() {
    return super
        .test_checkFinalConditions_shadowed_byLocalVariable_inSameClass();
  }

  @failingTest
  @override
  test_checkFinalConditions_shadowed_byLocalVariable_inSubClass() {
    return super
        .test_checkFinalConditions_shadowed_byLocalVariable_inSubClass();
  }
}
