// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.convert_method_to_getter;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' hide ElementKind;
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'abstract_refactoring.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ConvertMethodToGetterTest);
}


@ReflectiveTestCase()
class ConvertMethodToGetterTest extends RefactoringTest {
  ConvertMethodToGetterRefactoring refactoring;

  test_change_function() {
    indexTestUnit('''
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

  test_change_method() {
    indexTestUnit('''
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

  test_checkInitialConditions_alreadyGetter() {
    indexTestUnit('''
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

  test_checkInitialConditions_hasParameters() {
    indexTestUnit('''
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

  test_checkInitialConditions_localFunction() {
    indexTestUnit('''
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

  test_checkInitialConditions_notFunctionOrMethod() {
    indexTestUnit('''
class A {
  A.test();
}
''');
    _createRefactoring('test');
    // check conditions
    _assertInitialConditions_fatal(
        'Only class methods or top-level functions can be converted to getters.');
  }

  Future _assertInitialConditions_fatal(String message) {
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage: message);
    });
  }

  /**
   * Checks that all conditions are OK and the result of applying the [Change]
   * to [testUnit] is [expectedCode].
   */
  Future _assertSuccessfulRefactoring(String expectedCode) {
    return assertRefactoringConditionsOK().then((_) {
      return refactoring.createChange().then((SourceChange refactoringChange) {
        this.refactoringChange = refactoringChange;
        assertTestChangeResult(expectedCode);
      });
    });
  }

  void _createRefactoring(String elementName) {
    ExecutableElement element = findElement(elementName);
    _createRefactoringForElement(element);
  }

  void _createRefactoringForElement(ExecutableElement element) {
    refactoring = new ConvertMethodToGetterRefactoring(searchEngine, element);
  }

  void _createRefactoringForString(String search) {
    ExecutableElement element = findNodeElementAtString(search);
    _createRefactoringForElement(element);
  }
}
