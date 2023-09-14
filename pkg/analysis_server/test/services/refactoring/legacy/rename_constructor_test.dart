// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameConstructorClassTest);
    defineReflectiveTests(RenameConstructorEnumTest);
    defineReflectiveTests(RenameConstructorExtensionTypeTest);
  });
}

@reflectiveTest
class RenameConstructorClassTest extends _RenameConstructorTest {
  Future<void> test_checkInitialConditions_inSDK() async {
    await indexTestUnit('''
void f() {
  new String.fromCharCodes([]);
}
''');
    createRenameRefactoringAtString('fromCharCodes(');
    // check status
    refactoring.newName = 'newName';
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The constructor 'String.fromCharCodes' is defined in the SDK, so cannot be renamed.");
  }

  Future<void> test_checkNewName() async {
    await indexTestUnit('''
class A {
  A.test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    expect(refactoring.oldName, 'test');
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'The new name must be different than the current name.');
    // empty
    refactoring.newName = '';
    assertRefactoringStatusOK(refactoring.checkNewName());
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_hasMember_constructor() async {
    await indexTestUnit('''
class A {
  A.test() {}
  A.newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = refactoring.checkNewName();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Class 'A' already declares constructor with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  Future<void> test_checkNewName_hasMember_method() async {
    await indexTestUnit('''
class A {
  A.test() {}
  newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test() {}');
    // check status
    refactoring.newName = 'newName';
    var status = refactoring.checkNewName();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Class 'A' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  Future<void> test_createChange_add() async {
    await indexTestUnit('''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [new A] and [A.new]
class A {
  A() {} // marker
  factory A._() = A;
}
class B extends A {
  B() : super() {}
}
void f() {
  new A();
  A.new;
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
// ignore: deprecated_new_in_comment_reference
/// Documentation for [new A.newName] and [A.newName]
class A {
  A.newName() {} // marker
  factory A._() = A.newName;
}
class B extends A {
  B() : super.newName() {}
}
void f() {
  new A.newName();
  A.newName;
}
''');
  }

  Future<void> test_createChange_add_toSynthetic() async {
    await indexTestUnit('''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [new A] and [A.new]
class A {
  int field = 0;
}
class B extends A {
  B() : super() {}
}
void f() {
  new A();
  A.new;
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
// ignore: deprecated_new_in_comment_reference
/// Documentation for [new A.newName] and [A.newName]
class A {
  int field = 0;

  A.newName();
}
class B extends A {
  B() : super.newName() {}
}
void f() {
  new A.newName();
  A.newName;
}
''');
  }

  Future<void> test_createChange_change() async {
    await indexTestUnit('''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [A.test] and [new A.test]
class A {
  A.test() {} // marker
  factory A._() = A.test;
}
class B extends A {
  B() : super.test() {}
}
void f() {
  new A.test();
  A.test;
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
// ignore: deprecated_new_in_comment_reference
/// Documentation for [A.newName] and [new A.newName]
class A {
  A.newName() {} // marker
  factory A._() = A.newName;
}
class B extends A {
  B() : super.newName() {}
}
void f() {
  new A.newName();
  A.newName;
}
''');
  }

  Future<void>
      test_createChange_implicitlyInvoked_hasConstructor_hasInitializers() async {
    await indexTestUnit('''
class A {
  A();
}

class B extends A {
  var field;
  B() : field = 0;
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('A();');
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
  var field;
  B() : field = 0, super.newName();
}
''');
  }

  Future<void>
      test_createChange_implicitlyInvoked_hasConstructor_noInitializers() async {
    await indexTestUnit('''
class A {
  A();
}

class B extends A {
  B();
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('A();');
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
  B() : super.newName();
}
''');
  }

  Future<void> test_createChange_implicitlyInvoked_noConstructor() async {
    await indexTestUnit('''
class A {
  A();
}

class B extends A {
  void foo() {}
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('A();');
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
  B() : super.newName();
  void foo() {}
}
''');
  }

  Future<void> test_createChange_lint_sortConstructorsFirst() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_constructors_first]);
    await indexTestUnit('''
class A {
  int field = 0;
}
void f() {
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

  int field = 0;
}
void f() {
  new A.newName();
}
''');
  }

  Future<void> test_createChange_remove() async {
    await indexTestUnit('''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [A.test] and [new A.test]
class A {
  A.test() {} // marker
  factory A._() = A.test;
}
class B extends A {
  B() : super.test() {}
}
void f() {
  new A.test();
  A.test;
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
// ignore: deprecated_new_in_comment_reference
/// Documentation for [A] and [new A]
class A {
  A() {} // marker
  factory A._() = A;
}
class B extends A {
  B() : super() {}
}
void f() {
  new A();
  A.new;
}
''');
  }

  Future<void> test_newInstance_nullElement() async {
    await indexTestUnit('');
    var workspace = RefactoringWorkspace([driverFor(testFile)], searchEngine);
    var refactoring =
        RenameRefactoring.create(workspace, testAnalysisResult, null);
    expect(refactoring, isNull);
  }
}

@reflectiveTest
class RenameConstructorEnumTest extends _RenameConstructorTest {
  Future<void> test_checkNewName() async {
    await indexTestUnit('''
enum E {
  v.test();
  const E.test(); // 0
}
''');
    createRenameRefactoringAtString('test(); // 0');
    expect(refactoring.oldName, 'test');
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'The new name must be different than the current name.');
    // empty
    refactoring.newName = '';
    assertRefactoringStatusOK(refactoring.checkNewName());
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_hasMember_constructor() async {
    await indexTestUnit('''
enum E {
  v.test();
  const E.test(); // 0
  const E.newName(); // existing
}
''');
    _createConstructorDeclarationRefactoring('test(); // 0');
    // check status
    refactoring.newName = 'newName';
    var status = refactoring.checkNewName();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Enum 'E' already declares constructor with name 'newName'.",
        expectedContextSearch: 'newName(); // existing');
  }

  Future<void> test_checkNewName_hasMember_method() async {
    await indexTestUnit('''
enum E {
  v.test();
  const E.test(); // 0
  void newName() {} // existing
}
''');
    _createConstructorDeclarationRefactoring('test(); // 0');
    // check status
    refactoring.newName = 'newName';
    var status = refactoring.checkNewName();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Enum 'E' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  Future<void> test_createChange_add() async {
    await indexTestUnit('''
/// [E.new]
enum E {
  v1(), v2.new(), v3, v4.other();
  const E(); // 0
  const E.other() : this();
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('(); // 0');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName(), v4.other();
  const E.newName(); // 0
  const E.other() : this.newName();
}
''');
  }

  Future<void> test_createChange_add_toSynthetic_hasConstructor() async {
    await indexTestUnit('''
/// [E.new]
enum E {
  v1(), v2.new(), v3;

  factory E.other() => throw 0;
}
''');
    // configure refactoring
    _createEnumConstantRefactoring('v1()');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName();

  factory E.other() => throw 0;

  const E.newName();
}
''');
  }

  Future<void> test_createChange_add_toSynthetic_hasField() async {
    await indexTestUnit('''
/// [E.new]
enum E {
  v1(), v2.new(), v3;

  final int foo = 0;
}
''');
    // configure refactoring
    _createEnumConstantRefactoring('v1()');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName();

  final int foo = 0;

  const E.newName();
}
''');
  }

  Future<void> test_createChange_add_toSynthetic_hasMethod() async {
    await indexTestUnit('''
/// [E.new]
enum E {
  v1(), v2.new(), v3;

  void foo() {}
}
''');
    // configure refactoring
    _createEnumConstantRefactoring('v1()');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName();

  const E.newName();

  void foo() {}
}
''');
  }

  Future<void> test_createChange_add_toSynthetic_hasSemicolon() async {
    await indexTestUnit('''
/// [E.new]
enum E {
  v1(), v2.new(), v3;
}
''');
    // configure refactoring
    _createEnumConstantRefactoring('v1()');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName();

  const E.newName();
}
''');
  }

  Future<void> test_createChange_add_toSynthetic_noSemicolon() async {
    await indexTestUnit('''
/// [E.new]
enum E {
  v1(), v2.new(), v3
}
''');
    // configure refactoring
    _createEnumConstantRefactoring('v1()');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName();

  const E.newName();
}
''');
  }

  Future<void> test_createChange_change() async {
    await indexTestUnit('''
/// [E.test]
enum E {
  v1.test(), v2.other();
  const E.test(); // 0
  const E.other() : this.test();
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('test(); // 0');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, 'test');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
enum E {
  v1.newName(), v2.other();
  const E.newName(); // 0
  const E.other() : this.newName();
}
''');
  }

  Future<void> test_createChange_remove() async {
    await indexTestUnit('''
/// [E]
enum E {
  v1.test(), v2.other();
  const E.test(); // 0
  const E.other() : this.test();
}
''');
    // configure refactoring
    _createConstructorDeclarationRefactoring('test(); // 0');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, 'test');
    // validate change
    refactoring.newName = '';
    return assertSuccessfulRefactoring('''
/// [E]
enum E {
  v1(), v2.other();
  const E(); // 0
  const E.other() : this();
}
''');
  }

  void _createEnumConstantRefactoring(String search) {
    var enumConstant = findNode.enumConstantDeclaration(search);
    var element = enumConstant.constructorElement;
    createRenameRefactoringForElement(element);
  }
}

@reflectiveTest
class RenameConstructorExtensionTypeTest extends _RenameConstructorTest {
  Future<void> test_checkNewName() async {
    await indexTestUnit('''
extension type E.test(int it) {}
''');
    createRenameRefactoringAtString('test(int it)');
    expect(refactoring.oldName, 'test');
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'The new name must be different than the current name.');
    // empty
    refactoring.newName = '';
    assertRefactoringStatusOK(refactoring.checkNewName());
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_hasMember_constructor() async {
    await indexTestUnit('''
extension type E.test(int it) {
  E.newName() : this.test(0);
}
''');
    createRenameRefactoringAtString('test(int it)');
    // check status
    refactoring.newName = 'newName';
    var status = refactoring.checkNewName();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Extension type 'E' already declares constructor with name "
            "'newName'.",
        expectedContextSearch: 'newName() :');
  }

  Future<void> test_checkNewName_hasMember_method() async {
    await indexTestUnit('''
extension type E.test(int it) {
  void newName() {} // existing
}
''');
    createRenameRefactoringAtString('test(int it)');
    // check status
    refactoring.newName = 'newName';
    var status = refactoring.checkNewName();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            "Extension type 'E' already declares method with name 'newName'.",
        expectedContextSearch: 'newName() {} // existing');
  }

  Future<void> test_createChange_primary_add() async {
    await indexTestUnit('''
/// [E.new]
extension type E(int it) {
  E.other() : this(0);
}

void f() {
  E(0);
  E.new;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('new;');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
extension type E.newName(int it) {
  E.other() : this.newName(0);
}

void f() {
  E.newName(0);
  E.newName;
}
''');
  }

  Future<void> test_createChange_primary_change() async {
    await indexTestUnit('''
/// [E.test]
extension type E.test(int it) {
  E.other() : this.test(0);
}

void f() {
  E.test(0);
  E.test;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test(int it)');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, 'test');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
extension type E.newName(int it) {
  E.other() : this.newName(0);
}

void f() {
  E.newName(0);
  E.newName;
}
''');
  }

  Future<void> test_createChange_primary_remove() async {
    await indexTestUnit('''
/// [E.test]
extension type E.test(int it) {
  E.other() : this.test(0);
}

void f() {
  E.test(0);
  E.test;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test(int it)');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, 'test');
    // validate change
    refactoring.newName = '';
    return assertSuccessfulRefactoring('''
/// [E]
extension type E(int it) {
  E.other() : this(0);
}

void f() {
  E(0);
  E.new;
}
''');
  }

  Future<void> test_createChange_secondary_add() async {
    await indexTestUnit('''
/// [E.new]
extension type E.named(int it) {
  E() : this.named(0);
  E.other() : this();
}

void f() {
  E();
  E.new;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('E() :');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, '');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
extension type E.named(int it) {
  E.newName() : this.named(0);
  E.other() : this.newName();
}

void f() {
  E.newName();
  E.newName;
}
''');
  }

  Future<void> test_createChange_secondary_change() async {
    await indexTestUnit('''
/// [E.test]
extension type E(int it) {
  E.test() : this(0);
  E.other() : this.test();
}

void f() {
  E.test();
  E.test;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() :');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, 'test');
    // validate change
    refactoring.newName = 'newName';
    return assertSuccessfulRefactoring('''
/// [E.newName]
extension type E(int it) {
  E.newName() : this(0);
  E.other() : this.newName();
}

void f() {
  E.newName();
  E.newName;
}
''');
  }

  Future<void> test_createChange_secondary_remove() async {
    await indexTestUnit('''
/// [E.test]
extension type E.named(int it) {
  E.test() : this.named(0);
  E.other() : this.test();
}

void f() {
  E.test();
  E.test;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('E.test() :');
    expect(refactoring.refactoringName, 'Rename Constructor');
    expect(refactoring.elementKindName, 'constructor');
    expect(refactoring.oldName, 'test');
    // validate change
    refactoring.newName = '';
    return assertSuccessfulRefactoring('''
/// [E]
extension type E.named(int it) {
  E() : this.named(0);
  E.other() : this();
}

void f() {
  E();
  E.new;
}
''');
  }
}

class _RenameConstructorTest extends RenameRefactoringTest {
  void _createConstructorDeclarationRefactoring(String search) {
    var element = findNode.constructor(search).declaredElement;
    createRenameRefactoringForElement(element);
  }

  void _createConstructorInvocationRefactoring(String search) {
    var instanceCreation = findNode.instanceCreation(search);
    var element = instanceCreation.constructorName.staticElement;
    createRenameRefactoringForElement(element);
  }
}
