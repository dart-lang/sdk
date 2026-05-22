// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternAssignmentNotLocalVariableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PatternAssignmentNotLocalVariableTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  (int) = 0;
// ^^^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
}
''');
  }

  test_class_instanceField_ofSelf() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  var x = 0;

  void f() {
    (x) = 0;
//   ^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
  }
}
''');

    var node = result.findNode.singlePatternAssignment;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  var x = 0;
}

class B extends A {
  void f() {
    (x) = 0;
//   ^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
  }
}
''');

    var node = result.findNode.singlePatternAssignment;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static var x = 0;

  void f() {
    (x) = 0;
//   ^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
  }
}
''');

    var node = result.findNode.singlePatternAssignment;
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
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void f() {
    (T) = 0;
//   ^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
  }
}
''');
  }

  test_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  (dynamic) = 0;
// ^^^^^^^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
}
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  (f) = 0;
// ^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
}
''');
  }

  test_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
var x = 0;

void f() {
  (x) = 0;
// ^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
}
''');
  }
}
