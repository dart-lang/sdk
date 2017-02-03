// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.convert_method_to_getter;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart'
    show RefactoringProblemSeverity, SourceChange;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertMethodToGetterTest);
    defineReflectiveTests(ConvertMethodToGetterTest_Driver);
  });
}

@reflectiveTest
class ConvertMethodToGetterTest extends RefactoringTest {
  ConvertMethodToGetterRefactoring refactoring;

  test_change_function() async {
    await indexTestUnit('''
int test() => 42;
main() {
  var a = test();
  var b = test();
}
''');
    _createRefactoring('test');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int get test => 42;
main() {
  var a = test;
  var b = test;
}
''');
  }

  test_change_method() async {
    await indexTestUnit('''
class A {
  int test() => 1;
}
class B extends A {
  int test() => 2;
}
class C extends B {
  int test() => 3;
}
class D extends A {
  int test() => 4;
}
main(A a, B b, C c, D d) {
  var va = a.test();
  var vb = b.test();
  var vc = c.test();
  var vd = d.test();
}
''');
    _createRefactoringForString('test() => 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  int get test => 1;
}
class B extends A {
  int get test => 2;
}
class C extends B {
  int get test => 3;
}
class D extends A {
  int get test => 4;
}
main(A a, B b, C c, D d) {
  var va = a.test;
  var vb = b.test;
  var vc = c.test;
  var vd = d.test;
}
''');
  }

  test_change_multipleFiles() async {
    await indexUnit(
        '/other.dart',
        r'''
class A {
  int test() => 1;
}
''');
    await indexTestUnit('''
import 'other.dart';
class B extends A {
  int test() => 2;
}
main(A a, B b) {
  a.test();
  b.test();
}
''');
    _createRefactoringForString('test() => 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'other.dart';
class B extends A {
  int get test => 2;
}
main(A a, B b) {
  a.test;
  b.test;
}
''');
  }

  test_checkInitialConditions_alreadyGetter() async {
    await indexTestUnit('''
int get test => 42;
main() {
  var a = test;
  var b = test;
}
''');
    ExecutableElement element = findElement('test', ElementKind.GETTER);
    _createRefactoringForElement(element);
    // check conditions
    _assertInitialConditions_fatal(
        'Only class methods or top-level functions can be converted to getters.');
  }

  test_checkInitialConditions_hasParameters() async {
    await indexTestUnit('''
int test(x) => x * 2;
main() {
  var v = test(1);
}
''');
    _createRefactoring('test');
    // check conditions
    _assertInitialConditions_fatal(
        'Only methods without parameters can be converted to getters.');
  }

  test_checkInitialConditions_localFunction() async {
    await indexTestUnit('''
main() {
  test() {}
  var v = test();
}
''');
    _createRefactoring('test');
    // check conditions
    _assertInitialConditions_fatal(
        'Only top-level functions can be converted to getters.');
  }

  test_checkInitialConditions_notFunctionOrMethod() async {
    await indexTestUnit('''
class A {
  A.test();
}
''');
    _createRefactoring('test');
    // check conditions
    _assertInitialConditions_fatal(
        'Only class methods or top-level functions can be converted to getters.');
  }

  test_checkInitialConditions_returnTypeVoid() async {
    await indexTestUnit('''
void test() {}
''');
    _createRefactoring('test');
    // check conditions
    _assertInitialConditions_fatal('Cannot convert function returning void.');
  }

  Future _assertInitialConditions_fatal(String message) async {
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage: message);
  }

  /**
   * Checks that all conditions are OK and the result of applying the [Change]
   * to [testUnit] is [expectedCode].
   */
  Future _assertSuccessfulRefactoring(String expectedCode) async {
    await assertRefactoringConditionsOK();
    SourceChange refactoringChange = await refactoring.createChange();
    this.refactoringChange = refactoringChange;
    assertTestChangeResult(expectedCode);
  }

  void _createRefactoring(String elementName) {
    ExecutableElement element = findElement(elementName);
    _createRefactoringForElement(element);
  }

  void _createRefactoringForElement(ExecutableElement element) {
    refactoring = new ConvertMethodToGetterRefactoring(
        searchEngine, astProvider, element);
  }

  void _createRefactoringForString(String search) {
    ExecutableElement element = findNodeElementAtString(search);
    _createRefactoringForElement(element);
  }
}

@reflectiveTest
class ConvertMethodToGetterTest_Driver extends ConvertMethodToGetterTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
