// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternAssignmentResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PatternAssignmentResolutionTest extends PubPackageResolutionTest {
  test_assignable_final_definitelyAssigned() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final int a;
  a = 0;
  (a) = 1;
// ^
// [diag.assignmentToFinalLocal] The final variable 'a' can only be set once.
  a;
}
''');
  }

  test_assignable_final_definitelyUnassigned() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final int a;
  (a) = 0;
  a;
}
''');
  }

  test_assignable_final_notDefinitelyUnassigned() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool flag) {
  final int a;
  if (flag) {
    a = 0;
  }
  (a) = 1;
// ^
// [diag.assignmentToFinalLocal] The final variable 'a' can only be set once.
  a;
}
''');
  }

  test_assignable_lateFinal_definitelyAssigned() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late final int a;
  a = 0;
  (a) = 1;
// ^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
  a;
}
''');
  }

  test_assignable_lateFinal_definitelyUnassigned() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  late final int a;
  (a) = 1;
  a;
}
''');
  }

  test_assignable_lateFinal_notDefinitelyAssigned() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool flag) {
  late final int a;
  if (flag) {
    a = 0;
  }
  (a) = 1;
  a;
}
''');
  }

  test_container_listPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> x, num a) {
  [a] = x;
}
''');
    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
        element: <testLibrary>::@function::f::@formalParameter::a
        matchedValueType: int
    rightBracket: ]
    matchedValueType: List<int>
    requiredType: List<int>
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: List<int>
  patternTypeSchema: List<num>
  staticType: List<int>
''');
  }

  test_container_objectPattern_implicitGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

void f(int foo) {
  A(:foo) = A();
}
''');
    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ObjectPattern
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          colon: :
        pattern: AssignedVariablePattern
          name: foo
          element: <testLibrary>::@function::f::@formalParameter::foo
          matchedValueType: int
        element: <testLibrary>::@class::A::@getter::foo
    rightParenthesis: )
    matchedValueType: A
  equals: =
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  patternTypeSchema: A
  staticType: A
''');
  }

  test_container_parenthesizedPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x, num a) {
  (a) = x;
}
''');
    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: a
      element: <testLibrary>::@function::f::@formalParameter::a
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  patternTypeSchema: num
  staticType: int
''');
  }

  test_container_parenthesizedPattern_schema() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  (a) = g();
}

T g<T>() => throw 0;
''');
    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: a
      element: <testLibrary>::@function::f::@formalParameter::a
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      element: <testLibrary>::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  patternTypeSchema: int
  staticType: int
''');
  }

  test_container_recordPattern_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo}) x, num a) {
  (foo: a,) = x;
}
''');
    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: foo
          colon: :
        pattern: AssignedVariablePattern
          name: a
          element: <testLibrary>::@function::f::@formalParameter::a
          matchedValueType: int
        element: <null>
    rightParenthesis: )
    matchedValueType: ({int foo})
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: ({int foo})
  patternTypeSchema: ({num foo})
  staticType: ({int foo})
''');
  }

  test_container_recordPattern_named_implicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  (:a) = (a: 0);
}
''');
    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          colon: :
        pattern: AssignedVariablePattern
          name: a
          element: <testLibrary>::@function::f::@formalParameter::a
          matchedValueType: int
        element: <null>
    rightParenthesis: )
    matchedValueType: ({int a})
  equals: =
  expression: RecordLiteral
    leftParenthesis: (
    fields
      RecordLiteralNamedField
        name: a
        colon: :
        fieldExpression: IntegerLiteral
          literal: 0
          staticType: int
    rightParenthesis: )
    staticType: ({int a})
  patternTypeSchema: ({int a})
  staticType: ({int a})
''');
  }

  test_container_recordPattern_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int,) x, num a) {
  (a,) = x;
}
''');
    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: AssignedVariablePattern
          name: a
          element: <testLibrary>::@function::f::@formalParameter::a
          matchedValueType: int
        element: <null>
    rightParenthesis: )
    matchedValueType: (int,)
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: (int,)
  patternTypeSchema: (num,)
  staticType: (int,)
''');
  }

  test_context_arrowBody_formalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f(int x) => (x) = 0;
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: x
      element: <testLibrary>::@function::f::@formalParameter::x
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: int
  staticType: int
''');
  }

  test_context_returnExpression_formalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f(int x) {
  return (x) = 0;
}
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: x
      element: <testLibrary>::@function::f::@formalParameter::x
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: int
  staticType: int
''');
  }

  test_context_variableInitializer_localVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int x = 1;
  var y = (x) = 0;
  x;
  y;
}
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: x
      element: x@17
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: int
  staticType: int
''');
  }

  test_declaredVariable_inPatternAssignment_referenced() async {
    // Note: the error is reporting during parsing but we test it here to make
    // sure that error recovery produces an AST that can be analyzed without
    // crashing.
    // The reference doesn't resolve so the errors include UNUSED_LOCAL_VARIABLE
    // and UNDEFINED_IDENTIFIER.
    await resolveTestCodeWithDiagnostics(r'''
void f(a, y) {
  [a, var d] = y;
//        ^
// [diag.patternAssignmentDeclaresVariable] Variable 'd' can't be declared in a pattern assignment.
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
  d;
//^
// [diag.undefinedIdentifier] Undefined name 'd'.
}
''');
  }

  test_declaredVariable_inPatternAssignment_unreferenced() async {
    // Note: the error is reporting during parsing but we test it here to make
    // sure that error recovery produces an AST that can be analyzed without
    // crashing.
    await resolveTestCodeWithDiagnostics(r'''
void f(a, y) {
  [a, var d] = y;
//        ^
// [diag.patternAssignmentDeclaresVariable] Variable 'd' can't be declared in a pattern assignment.
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
}
''');
  }

  test_final_becomesDefinitelyAssigned() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final int a;
  (a) = 0;
  a;
  a = 1;
//^
// [diag.assignmentToFinalLocal] The final variable 'a' can only be set once.
}
''');
  }

  test_promotes() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num a) {
  if (a is! int) {
    (a) = 0;
  }
  a;
}
''');
    var node = result.findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::f::@formalParameter::a
  staticType: int
''');
  }
}
