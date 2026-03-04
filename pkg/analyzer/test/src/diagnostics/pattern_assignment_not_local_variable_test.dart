// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternAssignmentNotLocalVariableTest);
  });
}

@reflectiveTest
class PatternAssignmentNotLocalVariableTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(
      '''
void f() {
  (int) = 0;
}
''',
      [error(diag.patternAssignmentNotLocalVariable, 14, 3)],
    );
  }

  test_class_instanceField_ofSelf() async {
    await assertErrorsInCode(
      '''
class A {
  var x = 0;

  void f() {
    (x) = 0;
  }
}
''',
      [error(diag.patternAssignmentNotLocalVariable, 42, 1)],
    );

    var node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: x
      element: <testLibrary>::@class::A::@setter::x
      matchedValueType: InvalidType
    rightParenthesis: )
    matchedValueType: InvalidType
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
  staticType: int
''');
  }

  test_class_instanceField_ofSuperClass() async {
    await assertErrorsInCode(
      '''
class A {
  var x = 0;
}

class B extends A {
  void f() {
    (x) = 0;
  }
}
''',
      [error(diag.patternAssignmentNotLocalVariable, 64, 1)],
    );

    var node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: x
      element: <testLibrary>::@class::A::@setter::x
      matchedValueType: InvalidType
    rightParenthesis: )
    matchedValueType: InvalidType
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
  staticType: int
''');
  }

  test_class_staticField() async {
    await assertErrorsInCode(
      '''
class A {
  static var x = 0;

  void f() {
    (x) = 0;
  }
}
''',
      [error(diag.patternAssignmentNotLocalVariable, 49, 1)],
    );

    var node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: x
      element: <testLibrary>::@class::A::@getter::x
      matchedValueType: InvalidType
    rightParenthesis: )
    matchedValueType: InvalidType
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
  staticType: int
''');
  }

  test_class_typeParameter() async {
    await assertErrorsInCode(
      '''
class A<T> {
  void f() {
    (T) = 0;
  }
}
''',
      [error(diag.patternAssignmentNotLocalVariable, 31, 1)],
    );
  }

  test_dynamic() async {
    await assertErrorsInCode(
      '''
void f() {
  (dynamic) = 0;
}
''',
      [error(diag.patternAssignmentNotLocalVariable, 14, 7)],
    );
  }

  test_function() async {
    await assertErrorsInCode(
      '''
void f() {
  (f) = 0;
}
''',
      [error(diag.patternAssignmentNotLocalVariable, 14, 1)],
    );
  }

  test_topLevelVariable() async {
    await assertErrorsInCode(
      '''
var x = 0;

void f() {
  (x) = 0;
}
''',
      [error(diag.patternAssignmentNotLocalVariable, 26, 1)],
    );
  }
}
