// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_class_member;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'abstract_rename.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(RenameClassMemberTest);
}


@ReflectiveTestCase()
class RenameClassMemberTest extends RenameRefactoringTest {
  test_checkFinalConditions_hasMember_MethodElement() {
    indexTestUnit('''
class A {
  test() {}
  newName() {} // existing
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Class 'A' already declares method with name 'newName'.",
          expectedContextSearch: 'newName() {} // existing');
    });
  }

  test_checkFinalConditions_OK_noShadow() {
    indexTestUnit('''
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
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatusOK(status);
    });
  }

  test_checkFinalConditions_shadowed_byLocal_inSameClass() {
    indexTestUnit('''
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
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage:
              "Usage of renamed method will be shadowed by local variable 'newName'.",
          expectedContextSearch: 'test(); // marker');
    });
  }

  test_checkFinalConditions_shadowed_byLocal_inSubClass() {
    indexTestUnit('''
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
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage:
              "Usage of renamed method will be shadowed by local variable 'newName'.",
          expectedContextSearch: 'test(); // marker');
    });
  }

  test_checkFinalConditions_shadowed_byLocal_OK_qualifiedReference() {
    indexTestUnit('''
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
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatusOK(status);
    });
  }

  test_checkFinalConditions_shadowed_byLocal_OK_renamedNotUsed() {
    indexTestUnit('''
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
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatusOK(status);
    });
  }

  test_checkFinalConditions_shadowed_byParameter_inSameClass() {
    indexTestUnit('''
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
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage:
              "Usage of renamed method will be shadowed by parameter 'newName'.",
          expectedContextSearch: 'test(); // marker');
    });
  }

  test_checkFinalConditions_shadowed_inSubClass() {
    indexTestUnit('''
class A {
  newName() {} // marker
}
class B extends A {
  test() {}
  main() {
    newName();
  }
}
''');
    createRenameRefactoringAtString('test() {}');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Renamed method will shadow method 'A.newName'.",
          expectedContextSearch: 'newName() {} // marker');
    });
  }

  test_checkFinalConditions_shadowsSuper_inSubClass_FieldElement() {
    indexTestUnit('''
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
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Renamed method will shadow field 'A.newName'.",
          expectedContextSearch: 'newName; // marker');
    });
  }

  test_checkFinalConditions_shadowsSuper_MethodElement() {
    indexTestUnit('''
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
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Renamed method will be shadowed by method 'B.newName'.",
          expectedContextSearch: 'newName() {} // marker');
    });
  }

  test_checkInitialConditions_operator() {
    indexTestUnit('''
class A {
  operator -(other) => this;
}
''');
    createRenameRefactoringAtString('-(other)');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
    });
  }

  test_checkNewName_FieldElement() {
    indexTestUnit('''
class A {
  int test;
}
''');
    createRenameRefactoringAtString('test;');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Field name must not be null.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_MethodElement() {
    indexTestUnit('''
class A {
  test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Method name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Method name must not be empty.");
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "The new name must be different than the current name.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange_FieldElement() {
    indexTestUnit('''
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

  test_createChange_FieldElement_constructorFieldInitializer() {
    indexTestUnit('''
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

  test_createChange_FieldElement_fieldFormalParameter() {
    indexTestUnit('''
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

  test_createChange_FieldElement_fieldFormalParameter_named() {
    indexTestUnit('''
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

  test_createChange_FieldElement_invocation() {
    indexTestUnit('''
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

  test_createChange_MethodElement() {
    indexTestUnit('''
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

  test_createChange_MethodElement_potential() {
    indexTestUnit('''
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
    return assertSuccessfulRefactoring('''
class A {
  newName() {}
}
main(var a) {
  a.newName(); // 1
  new A().newName();
  a.newName(); // 2
}
''').then((_) {
      assertPotentialEdits(['test(); // 1', 'test(); // 2']);
    });
  }

  test_createChange_MethodElement_potential_private_otherLibrary() {
    indexUnit('/lib.dart', '''
library lib;
main(p) {
  p._test();
}
''');
    indexTestUnit('''
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
    return assertSuccessfulRefactoring('''
class A {
  newName() {}
}
main(var a) {
  a.newName();
  new A().newName();
}
''').then((_) {
      assertNoFileChange('/lib.dart');
    });
  }

  test_createChange_PropertyAccessorElement_getter() {
    indexTestUnit('''
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

  test_createChange_PropertyAccessorElement_setter() {
    indexTestUnit('''
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

  test_createChange_TypeParameterElement() {
    indexTestUnit('''
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
