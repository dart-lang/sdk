// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide ElementKind;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertGetterToMethodTest);
  });
}

@reflectiveTest
class ConvertGetterToMethodTest extends RefactoringTest {
  @override
  late ConvertGetterToMethodRefactoring refactoring;

  Future<void> test_change_extensionMethod() async {
    await indexTestUnit('''
extension A on String {
  int get test => 1;
}
void f(String a) {
  var va = a.test;
}
''');
    var element = findElement.getter('test', of: 'A');
    _createRefactoringForElement(element);
    // apply refactoring
    return _assertSuccessfulRefactoring('''
extension A on String {
  int test() => 1;
}
void f(String a) {
  var va = a.test();
}
''');
  }

  Future<void> test_change_function() async {
    await indexTestUnit('''
int get test => 42;
void f() {
  var a = test;
  var b = test;
}
''');
    var element = findElement.topGet('test');
    _createRefactoringForElement(
      element,
    );
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int test() => 42;
void f() {
  var a = test();
  var b = test();
}
''');
  }

  Future<void> test_change_method() async {
    await indexTestUnit('''
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
    var element = findElement.getter('test', of: 'B');
    _createRefactoringForElement(element);
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
void f(A a, B b, C c, D d) {
  var va = a.test();
  var vb = b.test();
  var vc = c.test();
  var vd = d.test();
}
''');
  }

  Future<void> test_change_multipleFiles() async {
    await indexUnit('$testPackageLibPath/other.dart', r'''
class A {
  int get test => 1;
}
''');
    await indexTestUnit('''
import 'other.dart';
class B extends A {
  int get test => 2;
}
void f(A a, B b) {
  a.test;
  b.test;
}
''');
    var element = findElement.getter('test', of: 'B');
    _createRefactoringForElement(element);
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'other.dart';
class B extends A {
  int test() => 2;
}
void f(A a, B b) {
  a.test();
  b.test();
}
''');
  }

  Future<void> test_checkInitialConditions_outsideOfProject() async {
    // File outside of project.
    var externalFile = newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
String get foo => '';
''');
    var externalUnit = await getResolvedUnit(externalFile);

    await indexTestUnit(''); // Initialize project.

    var element = FindElement(externalUnit.unit).topVar('foo').getter!;
    _createRefactoringForElement(element);

    // check conditions
    await _assertInitialConditions_fatal(
        'Only getters in your workspace can be converted.');
  }

  Future<void> test_checkInitialConditions_syntheticGetter() async {
    await indexTestUnit('''
int test = 42;
void f() {
}
''');
    var element = findElement.topGet('test');
    _createRefactoringForElement(element);
    // check conditions
    await _assertInitialConditions_fatal(
        'Only explicit getters can be converted to methods.');
  }

  Future<void> _assertInitialConditions_fatal(String message) async {
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage: message);
  }

  /// Checks that all conditions are OK and the result of applying [refactoring]
  /// change to [testUnit] is [expectedCode].
  Future<void> _assertSuccessfulRefactoring(String expectedCode) async {
    await assertRefactoringConditionsOK();
    var refactoringChange = await refactoring.createChange();
    this.refactoringChange = refactoringChange;
    assertTestChangeResult(expectedCode);
  }

  void _createRefactoringForElement(PropertyAccessorElement element) {
    refactoring = ConvertGetterToMethodRefactoring(
        refactoringWorkspace, testAnalysisResult.session, element);
  }
}
