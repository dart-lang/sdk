// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.convert_getter_to_method;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' hide ElementKind;
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'abstract_refactoring.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ConvertGetterToMethodTest);
}


@ReflectiveTestCase()
class ConvertGetterToMethodTest extends RefactoringTest {
  ConvertGetterToMethodRefactoring refactoring;

  test_change_function() {
    indexTestUnit('''
int get test => 42;
main() {
  var a = test;
  var b = test;
}
''');
    _createRefactoring('test');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int test() => 42;
main() {
  var a = test();
  var b = test();
}
''');
  }

  test_change_method() {
    indexTestUnit('''
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
    _createRefactoringForString('test => 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
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
  }

  test_checkInitialConditions_syntheticGetter() {
    indexTestUnit('''
int test = 42;
main() {
}
''');
    _createRefactoring('test');
    // check conditions
    _assertInitialConditions_fatal(
        'Only explicit getters can be converted to methods.');
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
   * Checks that all conditions are OK and the result of applying [refactoring]
   * change to [testUnit] is [expectedCode].
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
    PropertyAccessorElement element =
        findElement(elementName, ElementKind.GETTER);
    _createRefactoringForElement(element);
  }

  void _createRefactoringForElement(ExecutableElement element) {
    refactoring = new ConvertGetterToMethodRefactoring(searchEngine, element);
  }

  void _createRefactoringForString(String search) {
    ExecutableElement element = findNodeElementAtString(search);
    _createRefactoringForElement(element);
  }
}
