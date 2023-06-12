// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show RefactoringProblemSeverity;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertMethodToGetterTest);
  });
}

@reflectiveTest
class ConvertMethodToGetterTest extends RefactoringTest {
  @override
  late ConvertMethodToGetterRefactoring refactoring;

  Future<void> test_change_function() async {
    await indexTestUnit('''
int test() => 42;
void f() {
  var a = test();
  var b = test();
}
''');
    var element = findElement.topFunction('test');
    _createRefactoringForElement(element);
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int get test => 42;
void f() {
  var a = test;
  var b = test;
}
''');
  }

  Future<void> test_change_method() async {
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
void f(A a, B b, C c, D d) {
  var va = a.test();
  var vb = b.test();
  var vc = c.test();
  var vd = d.test();
}
''');
    var element = findElement.method('test', of: 'B');
    _createRefactoringForElement(element);
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
void f(A a, B b, C c, D d) {
  var va = a.test;
  var vb = b.test;
  var vc = c.test;
  var vd = d.test;
}
''');
  }

  Future<void> test_change_multipleFiles() async {
    await indexUnit('$testPackageLibPath/other.dart', r'''
class A {
  int test() => 1;
}
''');
    await indexTestUnit('''
import 'other.dart';
class B extends A {
  int test() => 2;
}
void f(A a, B b) {
  a.test();
  b.test();
}
''');
    var element = findElement.method('test', of: 'B');
    _createRefactoringForElement(element);
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'other.dart';
class B extends A {
  int get test => 2;
}
void f(A a, B b) {
  a.test;
  b.test;
}
''');
  }

  Future<void> test_checkInitialConditions_alreadyGetter() async {
    await indexTestUnit('''
int get test => 42;
void f() {
  var a = test;
  var b = test;
}
''');
    var element = findElement.topGet('test');
    _createRefactoringForElement(element);
    // check conditions
    await _assertInitialConditions_fatal(
        'Only class methods or top-level functions can be converted to getters.');
  }

  Future<void> test_checkInitialConditions_hasParameters() async {
    await indexTestUnit('''
int test(x) => x * 2;
void f() {
  var v = test(1);
}
''');
    var element = findElement.topFunction('test');
    _createRefactoringForElement(element);
    // check conditions
    await _assertInitialConditions_fatal(
        'Only methods without parameters can be converted to getters.');
  }

  Future<void> test_checkInitialConditions_localFunction() async {
    await indexTestUnit('''
void f() {
  test() {}
  var v = test();
}
''');
    var element = findElement.localFunction('test');
    _createRefactoringForElement(element);
    // check conditions
    await _assertInitialConditions_fatal(
        'Only top-level functions can be converted to getters.');
  }

  Future<void> test_checkInitialConditions_notFunctionOrMethod() async {
    await indexTestUnit('''
class A {
  A.test();
}
''');
    var element = findElement.constructor('test');
    _createRefactoringForElement(element);
    // check conditions
    await _assertInitialConditions_fatal(
        'Only class methods or top-level functions can be converted to getters.');
  }

  Future<void> test_checkInitialConditions_outsideOfProject() async {
    // File outside of project.
    var externalFile = newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
String foo() => '';
''');
    var externalUnit = await getResolvedUnit(externalFile);

    await indexTestUnit(''); // Initialize project.

    var element = FindElement(externalUnit.unit).topFunction('foo');
    _createRefactoringForElement(element);

    // check conditions
    await _assertInitialConditions_fatal(
        'Only methods in your workspace can be converted.');
  }

  Future<void> test_checkInitialConditions_returnTypeVoid() async {
    await indexTestUnit('''
void test() {}
''');
    var element = findElement.topFunction('test');
    _createRefactoringForElement(element);
    // check conditions
    await _assertInitialConditions_fatal(
        'Cannot convert function returning void.');
  }

  Future<void> _assertInitialConditions_fatal(String message) async {
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage: message);
  }

  /// Checks that all conditions are OK and the result of applying the [Change]
  /// to [testUnit] is [expectedCode].
  Future<void> _assertSuccessfulRefactoring(String expectedCode) async {
    await assertRefactoringConditionsOK();
    var refactoringChange = await refactoring.createChange();
    this.refactoringChange = refactoringChange;
    assertTestChangeResult(expectedCode);
  }

  void _createRefactoringForElement(ExecutableElement element) {
    refactoring = ConvertMethodToGetterRefactoring(
        refactoringWorkspace, testAnalysisResult.session, element);
  }
}
