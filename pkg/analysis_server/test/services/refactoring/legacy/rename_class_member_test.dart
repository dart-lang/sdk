// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameClassMemberClassTest);
    defineReflectiveTests(RenameClassMemberEnumTest);
    defineReflectiveTests(RenameClassMemberExtensionTypeTest);
  });
}

@reflectiveTest
class RenameClassMemberClassTest extends RenameRefactoringTest {
  Future<void> test_atConstructor_named() async {
    await indexTestUnit('''
class A {
  final int foo;

  A({this.f^oo = 0});
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'bar';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void> test_atConstructor_named_subclasses() async {
    await indexTestUnit('''
class A {
  final int foo;

  A({this.f^oo = 0});
}

class B extends A {
  B({super.foo});
}

class C extends A {
  C(int foo) : super(foo: foo);
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'bar';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
    await assertSuccessfulRefactoring('''
class A {
  final int bar;

  A({this.bar = 0});
}

class B extends A {
  B({super.bar});
}

class C extends A {
  C(int foo) : super(bar: foo);
}
''');
  }

  Future<void> test_atConstructor_named_subclasses_toPrivate() async {
    await indexTestUnit('''
class A {
  final int foo;

  A({this.f^oo = 0});
}

class B extends A {
  B({super.foo});
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = '_foo';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
    await assertSuccessfulRefactoring('''
class A {
  final int _foo;

  A({int foo = 0}) : _foo = foo;
}

class B extends A {
  B({super.foo});
}
''');
  }

  Future<void> test_atConstructor_positional() async {
    await indexTestUnit('''
class A {
  int foo = 0;

  A(this.f^oo);
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'bar';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void> test_atConstructor_positional_subclasses_toPrivate() async {
    await indexTestUnit('''
class A {
  int foo = 0;

  A(this.fo^o);
}

class B extends A {
  B(super.foo);
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = '_foo';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
    await assertSuccessfulRefactoring('''
class A {
  int _foo = 0;

  A(this._foo);
}

class B extends A {
  B(super.foo);
}
''');
  }

  Future<void> test_checkFinalConditions_classNameConflict_sameClass() async {
    await indexTestUnit('''
class NewName {
  void [!t^est!]() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Renamed method has the same name as the declaring class 'NewName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_classNameConflict_subClass() async {
    await indexTestUnit('''
class A {
  void t^est() {}
}
class NewName extends A {
  void [!test!]() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Renamed method has the same name as the declaring class 'NewName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_classNameConflict_superClass() async {
    await indexTestUnit('''
class NewName {
  void [!test!]() {}
}
class B extends NewName {
  void ^test() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Renamed method has the same name as the declaring class 'NewName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_hasMember_MethodElement() async {
    await indexTestUnit('''
class A {
  ^test() {}
  [!newName!]() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Class 'A' already declares method with name 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_OK_dropSuffix() async {
    await indexTestUnit(r'''
abstract class A {
  void ^testOld();
}
class B implements A {
  void testOld() {}
}
''');
    createRenameRefactoring();
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
  t^est() {}
}
class C extends A {
  void f() {
    print(newName);
  }
}
''');
    createRenameRefactoring();
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
  int ba^r; // declaration

  B(this.bar);

  void referenceField() {
    bar;
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'foo';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
  test_checkFinalConditions_publicToPrivate_usedInNamedLibrary() async {
    await indexTestUnit('''
class A {
  te^st() {}
}
''');
    await indexUnit('$testPackageLibPath/lib.dart', '''
library my.lib;
import 'test.dart';

void f(A a) {
  a.test();
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = '_newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Renamed method will be invisible in '${convertPath("lib/lib.dart")}'.",
    );
  }

  Future<void>
  test_checkFinalConditions_publicToPrivate_usedInUnnamedLibrary() async {
    await indexTestUnit('''
class A {
  var fo^o = 1;
}
''');
    await indexUnit('$testPackageLibPath/lib.dart', '''
import 'test.dart';

void f(A a) {
  print(a.foo);
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = '_newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Renamed field will be invisible in '${convertPath("lib/lib.dart")}'.",
    );
  }

  Future<void>
  test_checkFinalConditions_shadowed_byLocalFunction_inSameClass() async {
    await indexTestUnit('''
class A {
  ^test() {}
  void f() {
    newName() {}
    [!test!]();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by function 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadowed_byLocalVariable_inSameClass() async {
    await indexTestUnit('''
class A {
  test^() {}
  void f() {
    var newName;
    [!test!]();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by local variable 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadowed_byLocalVariable_inSubClass() async {
    await indexTestUnit('''
class A {
  ^test() {}
}
class B extends A {
  void f() {
    var newName;
    [!test!]();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by local variable 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadowed_byLocalVariable_OK_qualifiedReference() async {
    await indexTestUnit('''
class A {
  ^test() {}
  void f() {
    var newName;
    this.test();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
  test_checkFinalConditions_shadowed_byLocalVariable_OK_renamedNotUsed() async {
    await indexTestUnit('''
class A {
  ^test() {}
  void f() {
    var newName;
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void>
  test_checkFinalConditions_shadowed_byParameter_inSameClass() async {
    await indexTestUnit('''
class A {
  ^test() {}
  void f(newName) {
    [!test!]();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by parameter 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_shadowedBySub_MethodElement() async {
    await indexTestUnit('''
class A {
  te^st() {}
}
class B extends A {
  [!newName!]() {}
  void f() {
    test();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Renamed method will be shadowed by method 'B.newName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_shadowsSuper_FieldElement() async {
    await indexTestUnit('''
class A {
  int [!newName!] = 0;
}
class B extends A {
  te^st() {}
}
class C extends B {
  void f() {
    print(newName);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Renamed method will shadow field 'A.newName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_shadowsSuper_MethodElement() async {
    await indexTestUnit('''
class A {
  [!newName!]() {}
}
class B extends A {
  te^st() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Renamed method will shadow method 'A.newName'.",
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadowsSuper_MethodElement_otherLib() async {
    var libCode = TestCode.parse(
      normalizeSource(r'''
class A {
  /*[0*/newName/*0]*/() {}
}
'''),
    );
    await indexUnit('$testPackageLibPath/lib.dart', libCode.code);
    await indexTestUnit('''
import 'lib.dart';
class B extends A {
  ^test() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Renamed method will shadow method 'A.newName'.",
      expectedContextRange: libCode.range.sourceRange,
    );
  }

  Future<void> test_checkInitialConditions_inSDK() async {
    await indexTestUnit('''
void f() {
  'abc'.toUp^perCase();
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.FATAL,
      expectedMessage:
          "The method 'String.toUpperCase' is defined in the SDK, so cannot be renamed.",
    );
  }

  Future<void> test_checkInitialConditions_operator() async {
    await indexTestUnit('''
class A {
  operator ^-(other) => this;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkNewName_FieldElement() async {
    await indexTestUnit('''
class A {
  int te^st = 0;
}
''');
    createRenameRefactoring();
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_MethodElement() async {
    await indexTestUnit('''
class A {
  tes^t() {}
}
''');
    createRenameRefactoring();
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Method name must not be empty.',
    );
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'The new name must be different than the current name.',
    );
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_FieldElement() async {
    await indexTestUnit('''
/// [A.test]
/// [B.test]
class A {
  int t^est = 0;
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
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.elementKindName, 'field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
/// [A.newName]
/// [B.newName]
class A {
  int newName = 0;
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
  final t^est;
  A() : test = 5;
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  final te^st;
  A(this.test);
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  final tes^t;
  A({this.test});
}
void f() {
  new A(test: 42);
}
''');
    // configure refactoring
    createRenameRefactoring();
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

  Future<void>
  test_createChange_FieldElement_fieldFormalParameter_named_superChain() async {
    await indexTestUnit('''
class A {
  final int tes^t;
  A({required this.test});
}

class B extends A {
  B({required super.test});
}

class C extends B {
  C({required super.test});
}
''');

    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.elementKindName, 'field');
    refactoring.newName = 'newName';

    return assertSuccessfulRefactoring('''
class A {
  final int newName;
  A({required this.newName});
}

class B extends A {
  B({required super.newName});
}

class C extends B {
  C({required super.newName});
}
''');
  }

  Future<void>
  test_createChange_FieldElement_fieldFormalParameter_positional_toPrivate() async {
    await indexTestUnit('''
class A {
  int te^st;
  int foo;
  A(this.test): assert(test != 0), foo = test {
    test;
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = '_test';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  int _test;
  int foo;
  A(this._test): assert(_test != 0), foo = _test {
    _test;
  }
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
  a.tes^t(2);
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  int get tes^t => 0;
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  void te^st() {}
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  void _te^st() {}
}
''');

    createRenameRefactoring();
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
  ^test() {}
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
    createRenameRefactoring();
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
  newName() {}
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
  /*[0*/test/*0]*/() {}
}
void f(var a) {
  a./*[1*/test/*1]*/();
  new A().test();
  a./*[2*/test/*2]*/();
}
''');
    // configure refactoring
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    await assertSuccessfulRefactoring('''
class A {
  newName() {}
}
void f(var a) {
  a.newName();
  new A().newName();
  a.newName();
}
''');
    assertPotentialEdits(indexes: [1, 2]);
  }

  Future<void> test_createChange_MethodElement_potential_inPubCache() async {
    var externalPath = '$packagesRootPath/aaa/lib/lib.dart';
    newFile(externalPath, r'''
processObj(p) {
  p.test();
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'aaa', rootPath: '$packagesRootPath/aaa'),
    );

    await indexTestUnit('''
import 'package:aaa/lib.dart';

class A {
  t^est() {}
}

void f(var a) {
  a.test();
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  _te^st() {}
}
void f(var a) {
  a._test();
  new A()._test();
}
''');
    // configure refactoring
    createRenameRefactoring();
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
      config:
          PackageConfigFileBuilder()
            ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );

    await indexTestUnit('''
import 'package:aaa/aaa.dart';

class B extends A {
  void te^st() {}
}

void f(A a, B b) {
  a.test();
  b.test();
}
''');
    createRenameRefactoring();
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
    expect(refactoringChange.edits.first.file, testFile.path);
  }

  Future<void> test_createChange_outsideOfProject_referenceInPart() async {
    newFile('/home/part.dart', r'''
part of 'test/bin/test.dart';

void foo(A a) {
  a.test();
}
''');

    // To use file:// URI.
    testFilePath = convertPath('/home/test/bin/test.dart');

    await indexTestUnit('''
part '../../part.dart';

class A {
  void tes^t() {}
}

void f(A a) {
  a.test();
}
''');
    createRenameRefactoring();
    refactoring.newName = 'newName';

    await assertSuccessfulRefactoring('''
part '../../part.dart';

class A {
  void newName() {}
}

void f(A a) {
  a.newName();
}
''');

    expect(refactoringChange.edits, hasLength(1));
    expect(refactoringChange.edits.first.file, testFile.path);
  }

  Future<void> test_createChange_PropertyAccessorElement_getter() async {
    await indexTestUnit('''
/// [A.test]
/// [B.test]
/// [C.test]
class A {
  get t^est {}
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
    createRenameRefactoring();
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
  set t^est(x) {}
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
    createRenameRefactoring();
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

  Future<void> test_createChange_TypeParameterElement() async {
    await indexTestUnit('''
class A<T^est> {
  Test field;
  List<Test> items = [];
  A(this.field);
  Test method(Test p) => field;
}
''');
    // configure refactoring
    createRenameRefactoring();
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

  Future<void> test_shadowingLocalVariable_addsThis() async {
    await indexTestUnit('''
class A {
  final int? _va^lue;

  const A(this._value);

  A copyWith() {
    var value = _get();
    return A(value ?? _value);
  }

  int? _get() => null;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'value';
    await assertSuccessfulRefactoring('''
class A {
  final int? value;

  const A(this.value);

  A copyWith() {
    var value = _get();
    return A(value ?? this.value);
  }

  int? _get() => null;
}
''');
  }

  Future<void> test_shadowingParameter_addsThis() async {
    await indexTestUnit('''
class A {
  final int? _va^lue;

  const A(this._value);

  A copyWith({int? value}) {
    return A(value ?? _value);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'value';
    await assertSuccessfulRefactoring('''
class A {
  final int? value;

  const A(this.value);

  A copyWith({int? value}) {
    return A(value ?? this.value);
  }
}
''');
  }

  Future<void> test_shadowingTopLevelVariableGetter_addsThis() async {
    await indexTestUnit('''
int? value = 0;

class A {
  final int? _val^ue;

  const A(this._value);

  A copyWith() {
    return A(value ?? _value);
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'value';
    await assertSuccessfulRefactoring('''
int? value = 0;

class A {
  final int? value;

  const A(this.value);

  A copyWith() {
    return A(value ?? this.value);
  }
}
''');
  }

  Future<void> test_shadowingTopLevelVariableSetter_addsThis() async {
    await indexTestUnit('''
int? value = 0;

class A {
  final int? _val^ue;

  const A(this._value);

  void m() {
    value = _value ?? 0;
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'value';
    await assertSuccessfulRefactoring('''
int? value = 0;

class A {
  final int? value;

  const A(this.value);

  void m() {
    value = this.value ?? 0;
  }
}
''');
  }

  Future<void> test_subclass_namedSuper_otherLibrary() async {
    await indexTestUnit('''
class Base {
  final int f^oo;

  Base({required this.foo});
}
''');
    await indexUnit('$testPackageLibPath/sub1.dart', r'''
import 'test.dart';

class Sub1 extends Base {
  Sub1({required super.foo});
}
''');
    await indexUnit('$testPackageLibPath/sub2.dart', r'''
import 'test.dart';

class Sub2 extends Base {
  @override
  int get foo => 0;

  Sub2({required super.foo});
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'bar';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
    refactoringChange = await refactoring.createChange();
    assertFileChangeResult('$testPackageLibPath/sub2.dart', '''
import 'test.dart';

class Sub2 extends Base {
  @override
  int get bar => 0;

  Sub2({required super.bar});
}
''');
    assertFileChangeResult('$testPackageLibPath/sub1.dart', '''
import 'test.dart';

class Sub1 extends Base {
  Sub1({required super.bar});
}
''');
  }

  Future<void> test_subclass_namedSuper_sameLibrary() async {
    await indexTestUnit('''
class Base {
  final int fo^o;

  Base({required this.foo});
}

class Sub1 extends Base {
  Sub1({required super.foo});
}

class Sub2 extends Base {
  @override
  int get foo => 0;

  Sub2({required super.foo});
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'bar';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
    refactoringChange = await refactoring.createChange();
    assertTestChangeResult('''
class Base {
  final int bar;

  Base({required this.bar});
}

class Sub1 extends Base {
  Sub1({required super.bar});
}

class Sub2 extends Base {
  @override
  int get bar => 0;

  Sub2({required super.bar});
}
''');
  }

  Future<void> test_trailingNumber_add() async {
    await indexTestUnit('''
class A {
  int? foo^;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'foo2';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void> test_trailingNumber_remove() async {
    await indexTestUnit('''
class A {
  int? fo^o2;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'foo';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }
}

@reflectiveTest
class RenameClassMemberEnumTest extends RenameRefactoringTest {
  Future<void> test_checkFinalConditions_classNameConflict_sameClass() async {
    await indexTestUnit('''
enum NewName {
  v;
  void [!^test!]() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Renamed method has the same name as the declaring enum 'NewName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_classNameConflict_superClass() async {
    await indexTestUnit('''
class NewName {
  void [!test!]() {}
}
enum E implements NewName {
  v;
  void ^test() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'NewName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Renamed method has the same name as the declaring class 'NewName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_hasMember_MethodElement() async {
    await indexTestUnit('''
enum E {
  v;
  test^() {}
  [!newName!]() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Enum 'E' already declares method with name 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_OK_dropSuffix() async {
    await indexTestUnit(r'''
abstract class A {
  void testOld();
}
enum E implements A {
  v;
  void tes^tOld() {}
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'test';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  Future<void> test_checkFinalConditions_publicToPrivate_used() async {
    await indexTestUnit('''
enum E {
  v;
  void te^st() {}
}
''');
    await indexUnit('$testPackageLibPath/lib.dart', '''
import 'test.dart';

void f(E e) {
  e.test();
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = '_newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Renamed method will be invisible in '${convertPath("lib/lib.dart")}'.",
    );
  }

  Future<void>
  test_checkFinalConditions_shadowed_byLocalFunction_inSameClass() async {
    await indexTestUnit('''
enum E {
  v;
  void ^test() {}
  void f() {
    newName() {}
    [!test!]();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by function 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadowed_byLocalVariable_inSameClass() async {
    await indexTestUnit('''
enum E {
  v;
  void t^est() {}
  void f() {
    var newName;
    [!test!]();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by local variable 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadowed_byLocalVariable_OK_qualifiedReference() async {
    await indexTestUnit('''
enum E {
  v;
  void test^() {}
  void f() {
    var newName;
    this.test();
  }
}
''');
    createRenameRefactoring();
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
  void tes^t() {}
  void f() {
    var newName;
  }
}
''');
    createRenameRefactoring();
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
  void ^test() {}
  void f(newName) {
    [!test!]();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage:
          "Usage of renamed method will be shadowed by parameter 'newName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkFinalConditions_shadowsSuper_MethodElement() async {
    await indexTestUnit('''
mixin M {
  void [!newName!]() {}
}
enum E with M {
  v;
  void t^est() {}
  void f() {
    newName();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Renamed method will shadow method 'M.newName'.",
      rangeIndex: 0,
    );
  }

  Future<void>
  test_checkFinalConditions_shadowsSuper_MethodElement_otherLib() async {
    var libCode = TestCode.parse(
      normalizeSource(r'''
mixin M {
  void /*[0*/newName/*0]*/() {}
}
'''),
    );
    await indexUnit('$testPackageLibPath/lib.dart', libCode.code);
    await indexTestUnit('''
import 'lib.dart';
enum E with M {
  v;
  void ^test() {}
  void f() {
    newName();
  }
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Renamed method will shadow method 'M.newName'.",
      expectedContextRange: libCode.range.sourceRange,
    );
  }

  Future<void> test_checkInitialConditions_operator() async {
    await indexTestUnit('''
enum E {
  v;
  operator ^-() => this;
}
''');
    createRenameRefactoring();
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkNewName_FieldElement() async {
    await indexTestUnit('''
enum E {
  v;
  final int t^est = 0;
}
''');
    createRenameRefactoring();
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_MethodElement() async {
    await indexTestUnit('''
enum E {
  v;
  void ^test() {}
}
''');
    createRenameRefactoring();
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Method name must not be empty.',
    );
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'The new name must be different than the current name.',
    );
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_FieldElement() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit('''
enum E {
  v;
  final int tes^t = 0;
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
    createRenameRefactoring();
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
  final int ^test;
  const E() : test = 5;
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  final int t^est;
  const E(this.test);
}
''');
    // configure refactoring
    createRenameRefactoring();
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
  int? fie^ld;
  C(this.field);
}
void f() {
  var c = C(1);
  c.field = 1;
}
''');
    // configure refactoring
    createRenameRefactoring();
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
    var element = findElement2.field('field');
    createRenameRefactoringForElement2(element);
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
    var element = findElement2.field('field');
    createRenameRefactoringForElement2(element);
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
  void te^st() {}
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
    createRenameRefactoring();
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
  void te^st() {}
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
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  void newName() {}
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
  void t^est() {}
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
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
mixin M {
  void newName() {}
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
  int get te^st => 0;
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
    createRenameRefactoring();
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
enum E<T^est> {
  v;
  final Test? field = null;
  final List<Test> items = const [];
  Test method(Test a) => a;
}
''');
    // configure refactoring
    createRenameRefactoring();
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

@reflectiveTest
class RenameClassMemberExtensionTypeTest extends RenameRefactoringTest {
  Future<void> test_checkFinalConditions_shadowsSuper_MethodElement() async {
    await indexTestUnit('''
class A {
  void /*[0*/newName/*0]*/() {}
}
extension type E(A it) implements A {
  void /*[1*/test/*1]*/() {}
  void f() {
    newName();
  }
}
''');
    createRenameRefactoring(1);
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Renamed method will shadow method 'A.newName'.",
      rangeIndex: 0,
    );
  }

  Future<void> test_checkNewName_FieldElement_representation() async {
    await indexTestUnit('''
extension type E(int te^st) {}
''');
    createRenameRefactoring();
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_MethodElement() async {
    await indexTestUnit('''
extension type E(int it) {
  void t^est() {}
}
''');
    createRenameRefactoring();
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Method name must not be empty.',
    );
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'The new name must be different than the current name.',
    );
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_createChange_FieldElement_implicit() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit('''
extension type E(int it) {
  int get te^st => 0;
  set test(int _) {}
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
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.elementKindName, 'field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension type E(int it) {
  int get newName => 0;
  set newName(int _) {}
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

  Future<void> test_createChange_FieldElement_representation() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit('''
extension type E(int te^st) {
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
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.elementKindName, 'field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension type E(int newName) {
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

  Future<void> test_createChange_MethodElement() async {
    await indexTestUnit('''
extension type E(int it) {
  void t^est() {}
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
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension type E(int it) {
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

  Future<void> test_createChange_MethodElement_implements_class() async {
    await indexTestUnit('''
class A {
  void te^st() {}
}

extension type E(A it) implements A {
  void test() {}
  void foo() {
    test();
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  void newName() {}
}

extension type E(A it) implements A {
  void newName() {}
  void foo() {
    newName();
  }
}
''');
  }

  Future<void> test_createChange_MethodElement_implements_class2() async {
    await indexTestUnit('''
class A {
  void test() {}
}

extension type E(A it) implements A {
  void test^() {}
  void foo() {
    test();
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
class A {
  void newName() {}
}

extension type E(A it) implements A {
  void newName() {}
  void foo() {
    newName();
  }
}
''');
  }

  Future<void>
  test_createChange_MethodElement_implements_extensionType() async {
    await indexTestUnit('''
extension type E1(int it) {
  void t^est() {}
}

extension type E2(int it) implements E1 {
  void test() {}
  void foo() {
    test();
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension type E1(int it) {
  void newName() {}
}

extension type E2(int it) implements E1 {
  void newName() {}
  void foo() {
    newName();
  }
}
''');
  }

  Future<void>
  test_createChange_MethodElement_implements_extensionType2() async {
    await indexTestUnit('''
extension type E1(int it) {
  void test() {}
}

extension type E2(int it) implements E1 {
  void te^st() {}
  void foo() {
    test();
  }
}
''');
    // configure refactoring
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Method');
    expect(refactoring.elementKindName, 'method');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension type E1(int it) {
  void newName() {}
}

extension type E2(int it) implements E1 {
  void newName() {}
  void foo() {
    newName();
  }
}
''');
  }

  Future<void> test_createChange_PropertyAccessorElement() async {
    await indexTestUnit('''
extension type E(int it) {
  int get test^ => 0;
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
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Field');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
extension type E(int it) {
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
extension type E<^Test>(int it) {
  Test method(Test a) => a;
}
''');
    // configure refactoring
    createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Type Parameter');
    expect(refactoring.elementKindName, 'type parameter');
    expect(refactoring.oldName, 'Test');
    refactoring.newName = 'NewName';
    // validate change
    return assertSuccessfulRefactoring('''
extension type E<NewName>(int it) {
  NewName method(NewName a) => a;
}
''');
  }
}
