// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameClassMemberClassTest);
    defineReflectiveTests(RenameClassMemberEnumTest);
  });
}

@reflectiveTest
class RenameClassMemberClassTest extends RenameRefactoringTest {
  Future<void> test_checkFinalConditions_classNameConflict_sameClass() async {
    await indexTestUnit('''
class NewName {
  void test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method has the same name as the declaring class 'NewName'.",
        expectedContextSearch: 'test() {}');
  }

  Future<void> test_checkFinalConditions_classNameConflict_subClass() async {
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
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method has the same name as the declaring class 'NewName'.",
        expectedContextSearch: 'test() {} // 2');
  }

  Future<void> test_checkFinalConditions_classNameConflict_superClass() async {
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
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method has the same name as the declaring class 'NewName'.",
        expectedContextSearch: 'test() {} // 1');
  }

  Future<void> test_checkFinalConditions_hasMember_MethodElement() async {
    await indexTestUnit('''
class A {
  test() {}
  newName() {} // existing
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Class 'A' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  Future<void> test_checkFinalConditions_OK_dropSuffix() async {
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
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void> test_checkFinalConditions_OK_noShadow() async {
    await indexTestUnit('''
class A {
  int newName = 0;
}
class B {
  test() {}
}
class C extends A {
  void f() {
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void> test_checkFinalConditions_OK_noShadow_nullVisibleRange() async {
    await indexTestUnit('''
class A {
  int foo = 0;

  A(this.foo);
}

class B {
  int bar; // declaration

  B(this.bar);

  void referenceField() {
    bar;
  }
}
''');
    createRenameRefactoringAtString('bar; // declaration');
    // check status
    refactoring.newName = 'foo';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
      test_checkFinalConditions_publicToPrivate_usedInNamedLibrary() async {
    await indexTestUnit('''
class A {
  test() {}
}
''');
    await indexUnit('$testPackageLibPath/lib.dart', '''
library my.lib;
import 'test.dart';

void f(A a) {
  a.test();
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = '_newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method will be invisible in '${convertPath("lib/lib.dart")}'.");
  }

  Future<void>
      test_checkFinalConditions_publicToPrivate_usedInUnnamedLibrary() async {
    await indexTestUnit('''
class A {
  var foo = 1;
}
''');
    await indexUnit('$testPackageLibPath/lib.dart', '''
import 'test.dart';

void f(A a) {
  print(a.foo);
}
''');
    createRenameRefactoringAtString('foo');
    // check status
    refactoring.newName = '_newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed field will be invisible in '${convertPath("lib/lib.dart")}'.");
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalFunction_inSameClass() async {
    await indexTestUnit('''
class A {
  test() {}
  void f() {
    newName() {}
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by function 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalVariable_inSameClass() async {
    await indexTestUnit('''
class A {
  test() {}
  void f() {
    var newName;
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by local variable 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalVariable_inSubClass() async {
    await indexTestUnit('''
class A {
  test() {}
}
class B extends A {
  void f() {
    var newName;
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by local variable 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalVariable_OK_qualifiedReference() async {
    await indexTestUnit('''
class A {
  test() {}
  void f() {
    var newName;
    this.test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalVariable_OK_renamedNotUsed() async {
    await indexTestUnit('''
class A {
  test() {}
  void f() {
    var newName;
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
      test_checkFinalConditions_shadowed_byParameter_inSameClass() async {
    await indexTestUnit('''
class A {
  test() {}
  void f(newName) {
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by parameter 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  Future<void> test_checkFinalConditions_shadowedBySub_MethodElement() async {
    await indexTestUnit('''
class A {
  test() {}
}
class B extends A {
  newName() {} // marker
  void f() {
    test();
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method will be shadowed by method 'B.newName'.",
        expectedContextSearch: 'newName() {} // marker');
  }

  Future<void> test_checkFinalConditions_shadowsSuper_FieldElement() async {
    await indexTestUnit('''
class A {
  int newName = 0; // marker
}
class B extends A {
  test() {}
}
class C extends B {
  void f() {
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will shadow field 'A.newName'.",
        expectedContextSearch: 'newName = 0; // marker');
  }

  Future<void> test_checkFinalConditions_shadowsSuper_MethodElement() async {
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
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will shadow method 'A.newName'.",
        expectedContextSearch: 'newName() {} // marker');
  }

  Future<void>
      test_checkFinalConditions_shadowsSuper_MethodElement_otherLib() async {
    var libCode = r'''
class A {
  newName() {} // marker
}
''';
    await indexUnit('$testPackageLibPath/lib.dart', libCode);
    await indexTestUnit('''
import 'lib.dart';
class B extends A {
  test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will shadow method 'A.newName'.",
        expectedContextRange: SourceRange(
            libCode.indexOf('newName() {} // marker'), 'newName'.length));
  }

  Future<void> test_checkInitialConditions_inSDK() async {
    await indexTestUnit('''
void f() {
  'abc'.toUpperCase();
}
''');
    createRenameRefactoringAtString('toUpperCase()');
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The method 'String.toUpperCase' is defined in the SDK, so cannot be renamed.");
  }

  Future<void> test_checkInitialConditions_operator() async {
    await indexTestUnit('''
class A {
  operator -(other) => this;
}
''');
    createRenameRefactoringAtString('-(other)');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkNewName_FieldElement() async {
    await indexTestUnit('''
class A {
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0;');
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_MethodElement() async {
    await indexTestUnit('''
class A {
  test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Method name must not be empty.');
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'The new name must be different than the current name.');
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_FieldElement() async {
    await indexTestUnit('''
/// [A.test]
/// [B.test]
class A {
  int test = 0; // marker
  void f() {
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
void f() {
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
    createRenameRefactoringAtString('test = 0; // marker');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.elementKindName, 'field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
/// [A.newName]
/// [B.newName]
class A {
  int newName = 0; // marker
  void f() {
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
void f() {
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

  Future<void>
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

  Future<void> test_createChange_FieldElement_fieldFormalParameter() async {
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

  Future<void>
      test_createChange_FieldElement_fieldFormalParameter_named() async {
    await indexTestUnit('''
class A {
  final test;
  A({this.test});
}
void f() {
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
void f() {
  new A(newName: 42);
}
''');
  }

  Future<void> test_createChange_FieldElement_invocation() async {
    await indexTestUnit('''
typedef F(a);
class A {
  final F test;
  A(this.test);
  void f() {
    test(1);
  }
}
void f(A a) {
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
  final F newName;
  A(this.newName);
  void f() {
    newName(1);
  }
}
void f(A a) {
  a.newName(2);
}
''');
  }

  Future<void> test_createChange_getter_in_objectPattern() async {
    await indexTestUnit('''
void f(Object? x) {
  if (x case A(test: 0)) {}
  if (x case A(: var test)) {}
}

class A {
  int get test => 0;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test =>');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.elementKindName, 'field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(Object? x) {
  if (x case A(newName: 0)) {}
  if (x case A(newName: var test)) {}
}

class A {
  int get newName => 0;
}
''');
  }

  Future<void> test_createChange_method_in_objectPattern() async {
    await indexTestUnit('''
void f(Object? x) {
  if (x case A(test: _)) {}
  if (x case A(: var test)) {}
}

class A {
  void test() {}
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {}');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
void f(Object? x) {
  if (x case A(newName: _)) {}
  if (x case A(newName: var test)) {}
}

class A {
  void newName() {}
}
''');
  }

  Future<void> test_createChange_method_private() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _test() {}
}
''');

    newFile('$testPackageLibPath/c.dart', r'''
import 'test.dart';

class C extends B {
  void _test() {}
}
''');

    await indexTestUnit('''
import 'a.dart';

class B extends A {
  void _test() {}
}
''');

    createRenameRefactoringAtString('_test() {}');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, '_test');
    refactoring.newName = '_newName';

    await assertSuccessfulRefactoring2(r'''
>>>>>>>>>> /home/test/lib/test.dart
import 'a.dart';

class B extends A {
  void _newName() {}
}
''');
  }

  Future<void> test_createChange_MethodElement() async {
    await indexTestUnit('''
/// [A.test]
/// [B.test]
/// [F.test]
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
class F extends A {}
void f() {
  A a = new A();
  B b = new B();
  C c = new C();
  D d = new D();
  E e = new E();
  F f = new F();
  a.test();
  b.test();
  c.test();
  d.test();
  e.test();
  f.test();
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
/// [A.newName]
/// [B.newName]
/// [F.newName]
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
class F extends A {}
void f() {
  A a = new A();
  B b = new B();
  C c = new C();
  D d = new D();
  E e = new E();
  F f = new F();
  a.newName();
  b.newName();
  c.newName();
  d.newName();
  e.test();
  f.newName();
}
''');
  }

  Future<void> test_createChange_MethodElement_potential() async {
    await indexTestUnit('''
class A {
  test() {}
}
void f(var a) {
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
void f(var a) {
  a.newName(); // 1
  new A().newName();
  a.newName(); // 2
}
''');
    assertPotentialEdits(['test(); // 1', 'test(); // 2']);
  }

  Future<void> test_createChange_MethodElement_potential_inPubCache() async {
    var externalPath = '$packagesRootPath/aaa/lib/lib.dart';
    newFile(externalPath, r'''
processObj(p) {
  p.test();
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$packagesRootPath/aaa'),
    );

    await indexTestUnit('''
import 'package:aaa/lib.dart';

class A {
  test() {}
}

void f(var a) {
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
import 'package:aaa/lib.dart';

class A {
  newName() {}
}

void f(var a) {
  a.newName();
}
''');
    var fileEdit = refactoringChange.getFileEdit(externalPath);
    expect(fileEdit, isNull);
  }

  Future<void>
      test_createChange_MethodElement_potential_private_otherLibrary() async {
    await indexUnit('/lib.dart', '''
library lib;
void f(p) {
  p._test();
}
''');
    await indexTestUnit('''
class A {
  _test() {}
}
void f(var a) {
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
void f(var a) {
  a.newName();
  new A().newName();
}
''');
    assertNoFileChange('/lib.dart');
  }

  Future<void> test_createChange_outsideOfProject_declarationInPackage() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart', r'''
class A {
  void test() {}
}

void foo(A a) {
  a.test();
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );

    await indexTestUnit('''
import 'package:aaa/aaa.dart';

class B extends A {
  void test() {}
}

void f(A a, B b) {
  a.test();
  b.test();
}
''');
    createRenameRefactoringAtString('test() {}');
    refactoring.newName = 'newName';

    await assertSuccessfulRefactoring('''
import 'package:aaa/aaa.dart';

class B extends A {
  void newName() {}
}

void f(A a, B b) {
  a.newName();
  b.newName();
}
''');

    expect(refactoringChange.edits, hasLength(1));
    expect(refactoringChange.edits[0].file, testFile.path);
  }

  Future<void> test_createChange_outsideOfProject_referenceInPart() async {
    newFile('/home/part.dart', r'''
part of test;

void foo(A a) {
  a.test();
}
''');

    // To use file:// URI.
    testFilePath = convertPath('/home/test/bin/test.dart');

    await indexTestUnit('''
library test;

part '../../part.dart';

class A {
  void test() {}
}

void f(A a) {
  a.test();
}
''');
    createRenameRefactoringAtString('test() {}');
    refactoring.newName = 'newName';

    await assertSuccessfulRefactoring('''
library test;

part '../../part.dart';

class A {
  void newName() {}
}

void f(A a) {
  a.newName();
}
''');

    expect(refactoringChange.edits, hasLength(1));
    expect(refactoringChange.edits[0].file, testFile.path);
  }

  Future<void> test_createChange_PropertyAccessorElement_getter() async {
    await indexTestUnit('''
/// [A.test]
/// [B.test]
/// [C.test]
class A {
  get test {} // marker
  set test(x) {}
  void f() {
    print(test);
    test = 1;
  }
}
class B extends A {
  get test {}
  set test(x) {}
}
class C extends A {}
void f() {
  A a = new A();
  print(a.test);
  a.test = 2;

  B b = new B();
  print(b.test);
  b.test = 2;

  C c = new C();
  print(c.test);
  c.test = 2;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test {} // marker');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
/// [A.newName]
/// [B.newName]
/// [C.newName]
class A {
  get newName {} // marker
  set newName(x) {}
  void f() {
    print(newName);
    newName = 1;
  }
}
class B extends A {
  get newName {}
  set newName(x) {}
}
class C extends A {}
void f() {
  A a = new A();
  print(a.newName);
  a.newName = 2;

  B b = new B();
  print(b.newName);
  b.newName = 2;

  C c = new C();
  print(c.newName);
  c.newName = 2;
}
''');
  }

  Future<void> test_createChange_PropertyAccessorElement_setter() async {
    await indexTestUnit('''
/// [A.test]
/// [B.test]
/// [C.test]
class A {
  get test {}
  set test(x) {} // marker
  void f() {
    print(test);
    test = 1;
  }
}
class B extends A {
  get test {}
  set test(x) {}
}
class C extends A {}
void f() {
  A a = new A();
  print(a.test);
  a.test = 2;

  B b = new B();
  print(b.test);
  b.test = 2;

  C c = new C();
  print(c.test);
  c.test = 2;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test(x) {} // marker');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
/// [A.newName]
/// [B.newName]
/// [C.newName]
class A {
  get newName {}
  set newName(x) {} // marker
  void f() {
    print(newName);
    newName = 1;
  }
}
class B extends A {
  get newName {}
  set newName(x) {}
}
class C extends A {}
void f() {
  A a = new A();
  print(a.newName);
  a.newName = 2;

  B b = new B();
  print(b.newName);
  b.newName = 2;

  C c = new C();
  print(c.newName);
  c.newName = 2;
}
''');
  }

  Future<void> test_createChange_TypeParameterElement() async {
    await indexTestUnit('''
class A<Test> {
  Test field;
  List<Test> items = [];
  A(this.field);
  Test method(Test p) => field;
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
  List<NewName> items = [];
  A(this.field);
  NewName method(NewName p) => field;
}
''');
  }
}

@reflectiveTest
class RenameClassMemberEnumTest extends RenameRefactoringTest {
  Future<void> test_checkFinalConditions_classNameConflict_sameClass() async {
    await indexTestUnit('''
enum NewName {
  v;
  void test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method has the same name as the declaring enum 'NewName'.",
        expectedContextSearch: 'test() {}');
  }

  Future<void> test_checkFinalConditions_classNameConflict_superClass() async {
    await indexTestUnit('''
class NewName {
  void test() {} // 1
}
enum E implements NewName {
  v;
  void test() {} // 2
}
''');
    createRenameRefactoringAtString('test() {} // 2');
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method has the same name as the declaring class 'NewName'.",
        expectedContextSearch: 'test() {} // 1');
  }

  Future<void> test_checkFinalConditions_hasMember_MethodElement() async {
    await indexTestUnit('''
enum E {
  v;
  test() {}
  newName() {} // existing
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Enum 'E' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  Future<void> test_checkFinalConditions_OK_dropSuffix() async {
    await indexTestUnit(r'''
abstract class A {
  void testOld();
}
enum E implements A {
  v;
  void testOld() {}
}
''');
    createRenameRefactoringAtString('testOld() {}');
    // check status
    refactoring.newName = 'test';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void> test_checkFinalConditions_publicToPrivate_used() async {
    await indexTestUnit('''
enum E {
  v;
  void test() {}
}
''');
    await indexUnit('$testPackageLibPath/lib.dart', '''
import 'test.dart';

void f(E e) {
  e.test();
}
''');
    createRenameRefactoringAtString('test()');
    // check status
    refactoring.newName = '_newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Renamed method will be invisible in '${convertPath("lib/lib.dart")}'.");
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalFunction_inSameClass() async {
    await indexTestUnit('''
enum E {
  v;
  void test() {}
  void f() {
    newName() {}
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by function 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalVariable_inSameClass() async {
    await indexTestUnit('''
enum E {
  v;
  void test() {}
  void f() {
    var newName;
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by local variable 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalVariable_OK_qualifiedReference() async {
    await indexTestUnit('''
enum E {
  v;
  void test() {}
  void f() {
    var newName;
    this.test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
      test_checkFinalConditions_shadowed_byLocalVariable_OK_renamedNotUsed() async {
    await indexTestUnit('''
enum E {
  v;
  void test() {}
  void f() {
    var newName;
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
      test_checkFinalConditions_shadowed_byParameter_inSameClass() async {
    await indexTestUnit('''
enum E {
  v;
  void test() {}
  void f(newName) {
    test(); // marker
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Usage of renamed method will be shadowed by parameter 'newName'.",
        expectedContextSearch: 'test(); // marker');
  }

  Future<void> test_checkFinalConditions_shadowsSuper_MethodElement() async {
    await indexTestUnit('''
mixin M {
  void newName() {}
}
enum E with M {
  v;
  void test() {}
  void f() {
    newName();
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will shadow method 'M.newName'.",
        expectedContextSearch: 'newName() {}');
  }

  Future<void>
      test_checkFinalConditions_shadowsSuper_MethodElement_otherLib() async {
    var libCode = r'''
mixin M {
  void newName() {}
}
''';
    await indexUnit('$testPackageLibPath/lib.dart', libCode);
    await indexTestUnit('''
import 'lib.dart';
enum E with M {
  v;
  void test() {}
  void f() {
    newName();
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: "Renamed method will shadow method 'M.newName'.",
        expectedContextRange:
            SourceRange(libCode.indexOf('newName() {}'), 'newName'.length));
  }

  Future<void> test_checkInitialConditions_operator() async {
    await indexTestUnit('''
enum E {
  v;
  operator -() => this;
}
''');
    createRenameRefactoringAtString('-()');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkNewName_FieldElement() async {
    await indexTestUnit('''
enum E {
  v;
  final int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0;');
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_MethodElement() async {
    await indexTestUnit('''
enum E {
  v;
  void test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Method name must not be empty.');
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'The new name must be different than the current name.');
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_FieldElement() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit('''
enum E {
  v;
  final int test = 0;
  void f() {
    test;
    test = 1;
    test += 2;
  }
}
void f(E e) {
  e.test;
  e.test = 1;
  e.test += 2;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 0;');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.elementKindName, 'field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
enum E {
  v;
  final int newName = 0;
  void f() {
    newName;
    newName = 1;
    newName += 2;
  }
}
void f(E e) {
  e.newName;
  e.newName = 1;
  e.newName += 2;
}
''');
  }

  Future<void>
      test_createChange_FieldElement_constructorFieldInitializer() async {
    await indexTestUnit('''
enum E {
  v;
  final int test;
  const E() : test = 5;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test;');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
enum E {
  v;
  final int newName;
  const E() : newName = 5;
}
''');
  }

  Future<void> test_createChange_FieldElement_fieldFormalParameter() async {
    await indexTestUnit('''
enum E {
  v(0);
  final int test;
  const E(this.test);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test;');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
enum E {
  v(0);
  final int newName;
  const E(this.newName);
}
''');
  }

  Future<void> test_createChange_FieldElement_private() async {
    await indexTestUnit('''
class C {
  int? field;
  C(this.field);
}
void f() {
  var c = C(1);
  c.field = 1;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('field;');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'field');
    refactoring.newName = '_field';
    // validate change
    return assertSuccessfulRefactoring('''
class C {
  int? _field;
  C(this._field);
}
void f() {
  var c = C(1);
  c._field = 1;
}
''');
  }

  Future<void> test_createChange_FieldElement_private_initializer() async {
    await indexTestUnit('''
class C {
  int? field;
  int? other;
  C({this.field}) : other = field;
}
void f() {
  var c = C(field: 0);
  c.field = 1;
}
''');
    // configure refactoring
    var element = findElement.field('field');
    createRenameRefactoringForElement(element);
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'field');
    refactoring.newName = '_field';
    // validate change
    return assertSuccessfulRefactoring('''
class C {
  int? _field;
  int? other;
  C({int? field}) : _field = field, other = field;
}
void f() {
  var c = C(field: 0);
  c._field = 1;
}
''');
  }

  Future<void> test_createChange_FieldElement_private_positional() async {
    await indexTestUnit('''
class C {
  int? field;
  C([this.field]);
}
void f() {
  C().field;
}
''');
    // configure refactoring
    var element = findElement.field('field');
    createRenameRefactoringForElement(element);
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'field');
    refactoring.newName = '_field';
    // validate change
    return assertSuccessfulRefactoring('''
class C {
  int? _field;
  C([this._field]);
}
void f() {
  C()._field;
}
''');
  }

  Future<void> test_createChange_MethodElement() async {
    await indexTestUnit('''
enum E {
  v;
  void test() {}
  void foo() {
    test();
    test;
  }
}

void f(E e) {
  e.test();
  e.test;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {}');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
enum E {
  v;
  void newName() {}
  void foo() {
    newName();
    newName;
  }
}

void f(E e) {
  e.newName();
  e.newName;
}
''');
  }

  Future<void> test_createChange_MethodElement_fromInterface() async {
    await indexTestUnit('''
class A {
  void test() {} // A
}

enum E implements A {
  v;
  void test() {}
  void foo() {
    test();
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {} // A');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  void newName() {} // A
}

enum E implements A {
  v;
  void newName() {}
  void foo() {
    newName();
  }
}
''');
  }

  Future<void> test_createChange_MethodElement_fromMixin() async {
    await indexTestUnit('''
mixin M {
  void test() {} // M
}

enum E with M {
  v;
  void test() {}
  void foo() {
    test();
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() {} // M');
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
mixin M {
  void newName() {} // M
}

enum E with M {
  v;
  void newName() {}
  void foo() {
    newName();
  }
}
''');
  }

  Future<void> test_createChange_PropertyAccessorElement() async {
    await indexTestUnit('''
enum E {
  v;
  int get test => 0;
  set test(int _) {}
  void f() {
    test;
    test = 0;
  }
}
void f(E e) {
  e.test;
  e.test = 1;
  e.test += 2;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test => 0;');
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
enum E {
  v;
  int get newName => 0;
  set newName(int _) {}
  void f() {
    newName;
    newName = 0;
  }
}
void f(E e) {
  e.newName;
  e.newName = 1;
  e.newName += 2;
}
''');
  }

  Future<void> test_createChange_TypeParameterElement() async {
    await indexTestUnit('''
enum E<Test> {
  v;
  final Test? field = null;
  final List<Test> items = const [];
  Test method(Test a) => a;
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
enum E<NewName> {
  v;
  final NewName? field = null;
  final List<NewName> items = const [];
  NewName method(NewName a) => a;
}
''');
  }
}
