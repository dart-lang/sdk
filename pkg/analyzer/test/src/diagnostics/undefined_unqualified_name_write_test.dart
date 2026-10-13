// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedUnqualifiedNameWriteTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedUnqualifiedNameWriteTest extends PubPackageResolutionTest {
  test_const_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f() {
  foo += 1;
//^^^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_const_compoundAssignment_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x += 1;
//^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'x' can't be assigned to.
}''');
  }

  test_const_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f() {
  foo = 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_directAssignment_constInstanceField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  const foo = 0;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.

  void f() {
  foo = 0;
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_directAssignment_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = 1;
//^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'x' can't be assigned to.
}''');
  }

  test_const_directAssignment_staticConstField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static const foo = 0;

  void f() {
  foo = 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'foo' can't be assigned to.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_forIn() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f() {
  for (foo in [0]) {}
//     ^^^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleForEachPartsWithIdentifier;
    assertResolvedNodeText(node, r'''
ForEachPartsWithIdentifier
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  inKeyword: in
  iterable2: ListLiteral
    leftBracket: [
    elements2
      IntegerLiteral
        literal: 0
        staticType: int
    rightBracket: ]
    staticType: List<int>
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: InvalidType
''');
  }

  test_const_forIn_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const x = 0;
  for (x in <int>[1, 2]) {
//     ^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'x' can't be assigned to.
    print(x);
  }
}''');
  }

  test_const_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f() {
  foo ??= 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'foo' can't be assigned to.
//        ^^
// [diag.deadCode] Dead code.
//        ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f() {
  foo++;
//^^^
// [diag.undefinedUnqualifiedNameWriteConst] The constant 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_const_patternAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f() {
  (foo) = 0;
// ^^^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
}
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: foo
      element: <testLibrary>::@getter::foo
      matchedValueType: InvalidType
    rightParenthesis: )
    matchedValueType: InvalidType
  equals: =
  expression2: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
  staticType: int
''');
  }

  test_final_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final foo = 0;

void f() {
  foo += 1;
//^^^
// [diag.undefinedUnqualifiedNameWriteFinal] 'foo' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final foo = 0;

void f() {
  foo = 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteFinal] 'foo' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_extensionInstanceField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  final foo = 0;
//      ^^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.

  void f() {
    foo = 0;
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_externalFinalVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
external final x;

void f() {
  x = 0;
//^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
  x += 0;
//^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
  ++x;
//  ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
  x++;
//^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
}
''');
  }

  test_final_directAssignment_implicitThis() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final foo = 0;

  void f() {
  foo = 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteFinal] 'foo' is final, so it can't be assigned to.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_lateFinalInstanceField_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  late final int x = 0;

  void f() {
    x = 0;
//  ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
    x += 0;
//  ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
    ++x;
//    ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
    x++;
//  ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
  }
}
''');
  }

  test_final_directAssignment_lateFinalStaticField_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  static late final int x = 0;

  void f() {
    x = 0;
//  ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
    x += 0;
//  ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
    ++x;
//    ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
    x++;
//  ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
  }
}
''');
  }

  test_final_directAssignment_lateFinalVariable_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
late final int x = 0;

void f() {
  x = 0;
//^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
  x += 0;
//^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
  ++x;
//  ^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
  x++;
//^
// [diag.undefinedUnqualifiedNameWriteFinal] 'x' is final, so it can't be assigned to.
}
''');
  }

  test_final_forIn() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final foo = 0;

void f() {
  for (foo in [0]) {}
//     ^^^
// [diag.undefinedUnqualifiedNameWriteFinal] 'foo' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleForEachPartsWithIdentifier;
    assertResolvedNodeText(node, r'''
ForEachPartsWithIdentifier
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  inKeyword: in
  iterable2: ListLiteral
    leftBracket: [
    elements2
      IntegerLiteral
        literal: 0
        staticType: int
    rightBracket: ]
    staticType: List<int>
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: InvalidType
''');
  }

  test_final_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final foo = 0;

void f() {
  foo ??= 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteFinal] 'foo' is final, so it can't be assigned to.
//        ^^
// [diag.deadCode] Dead code.
//        ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final foo = 0;

void f() {
  foo++;
//^^^
// [diag.undefinedUnqualifiedNameWriteFinal] 'foo' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_patternAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final foo = 0;

void f() {
  (foo) = 0;
// ^^^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
}
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: foo
      element: <testLibrary>::@getter::foo
      matchedValueType: InvalidType
    rightParenthesis: )
    matchedValueType: InvalidType
  equals: =
  expression2: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
  staticType: int
''');
  }

  test_found_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int foo = 0;

void f() {
  foo += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::foo
      acceptedType: int
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int foo = 0;

void f() {
  foo = 0;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_externalVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
external int x;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''');
  }

  test_found_directAssignment_lateFinalInstanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  late final int x;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''');
  }

  test_found_directAssignment_lateFinalStaticField() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  static late final int x;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''');
  }

  test_found_directAssignment_lateFinalVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
late final int x;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''');
  }

  test_getterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

void f() {
  foo += 1;
//^^^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'foo', but no setter.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

void f() {
  foo = 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'foo', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_directAssignment_extensionGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;

  void f() {
    foo = 0;
//  ^^^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'foo', but no setter.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_directAssignment_implicitThis() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;

  void f() {
    x = 0;
//  ^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'x', but no setter.
    x += 0;
//  ^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'x', but no setter.
    ++x;
//    ^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'x', but no setter.
    x++;
//  ^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'x', but no setter.
  }
}
''');
  }

  test_getterOnly_directAssignment_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get x => 0;

  void f() {
    x = 0;
//  ^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'x', but no setter.
    x += 0;
//  ^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'x', but no setter.
    ++x;
//    ^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'x', but no setter.
    x++;
//  ^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'x', but no setter.
  }
}
''');
  }

  test_getterOnly_directAssignment_topLevelGetterHidesInheritedSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void set foo(int _) {}
}

int get foo => 0;

class B extends A {
  void bar() {
    foo = 0;
//  ^^^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'foo', but no setter.
  }
}
''');
  }

  test_getterOnly_forIn() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

void f() {
  for (foo in [0]) {}
//     ^^^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'foo', but no setter.
}
''');

    var node = result.findNode.singleForEachPartsWithIdentifier;
    assertResolvedNodeText(node, r'''
ForEachPartsWithIdentifier
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  inKeyword: in
  iterable2: ListLiteral
    leftBracket: [
    elements2
      IntegerLiteral
        literal: 0
        staticType: int
    rightBracket: ]
    staticType: List<int>
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: InvalidType
''');
  }

  test_getterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

void f() {
  foo ??= 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'foo', but no setter.
//        ^^
// [diag.deadCode] Dead code.
//        ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

void f() {
  foo++;
//^^^
// [diag.undefinedUnqualifiedNameWriteGetterOnly] There's a getter 'foo', but no setter.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_patternAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

void f() {
  (foo) = 0;
// ^^^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
}
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: foo
      element: <testLibrary>::@getter::foo
      matchedValueType: InvalidType
    rightParenthesis: )
    matchedValueType: InvalidType
  equals: =
  expression2: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
  staticType: int
''');
  }

  test_notFound_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  foo = 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_implicitThis() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {

  void f() {
  foo = 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteNotFound] Undefined name 'foo'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_inheritedPrivateOfOtherLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class A {
  var _foo;
}''');
    await resolveTestCodeWithDiagnostics('''
import 'lib.dart';
class B extends A {
  test() {
    _foo = 42;
//  ^^^^
// [diag.undefinedUnqualifiedNameWriteNotFound] Undefined name '_foo'.
  }
}''');
  }

  test_notFound_directAssignment_missingImportShowsIt() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show x;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

void f() {
  x = 0;
}
''');
  }

  test_notFound_directAssignment_missingImportShowsOther() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show y;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

void f() {
  x = 0;
//^
// [diag.undefinedUnqualifiedNameWriteNotFound] Undefined name 'x'.
}
''');
  }

  test_notFound_forIn() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (foo in [0]) {}
//     ^^^
// [diag.undefinedUnqualifiedNameWriteNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleForEachPartsWithIdentifier;
    assertResolvedNodeText(node, r'''
ForEachPartsWithIdentifier
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  inKeyword: in
  iterable2: ListLiteral
    leftBracket: [
    elements2
      IntegerLiteral
        literal: 0
        staticType: int
    rightBracket: ]
    staticType: List<int>
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
''');
  }

  test_notFound_forIn_loopVariableUsed() async {
    await resolveTestCodeWithDiagnostics('''
f(l) {
  for (e in l) {
//     ^
// [diag.undefinedUnqualifiedNameWriteNotFound] Undefined name 'e'.
  }
}''');
  }

  test_notFound_patternAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  (foo) = 0;
// ^^^
// [diag.undefinedUnqualifiedNameWriteNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: foo
      element: <null>
      matchedValueType: InvalidType
    rightParenthesis: )
    matchedValueType: InvalidType
  equals: =
  expression2: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
  staticType: int
''');
  }

  test_notFound_patternAssignment_missingImportShowsIt() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show x;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

void f() {
  (x) = 0;
}
''');
  }

  test_prefix_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as math;

void f() {
  math = 0;
//^^^^
// [diag.prefixIdentifierNotFollowedByDot] The name 'math' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: math
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibraryFragment>::@prefix::math
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: math
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibraryFragment>::@prefix::math
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  foo += 1;
//^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The function 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@function::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@function::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@function::foo
  readType: void Function()
  writeElement: <testLibrary>::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  foo = 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The function 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@function::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
main() {
  C = null;
//^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The class 'C' can't be assigned to.
}
''');
  }

  test_wrongKind_directAssignment_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  dynamic = 1;
//^^^^^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The type 'dynamic' can't be assigned to.
}
''');
  }

  test_wrongKind_directAssignment_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { e }
main() {
  E = null;
//^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The enum 'E' can't be assigned to.
}
''');
  }

  test_wrongKind_directAssignment_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E = 0;
//^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The extension 'E' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: E
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: E
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_implicitThisMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}

  void f() {
    foo = 0;
//  ^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The method 'foo' can't be assigned to.
  }
}
''');
  }

  test_wrongKind_directAssignment_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  Never = 0;
//^^^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The type 'Never' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: Never
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: Never
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: Never
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: Never
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_typeAliasOfFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void F();
main() {
  F = null;
//^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The type alias 'F' can't be assigned to.
}
''');
  }

  test_wrongKind_directAssignment_typeAliasOfInterfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = List<int>;

void f() {
  F = null;
//^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The type alias 'F' can't be assigned to.
}
''');
  }

  test_wrongKind_directAssignment_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  f() {
    T = null;
//  ^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The type parameter 'T' can't be assigned to.
  }
}
''');
  }

  test_wrongKind_forIn() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  for (foo in [0]) {}
//     ^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The function 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleForEachPartsWithIdentifier;
    assertResolvedNodeText(node, r'''
ForEachPartsWithIdentifier
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@function::foo
  inKeyword: in
  iterable2: ListLiteral
    leftBracket: [
    elements2
      IntegerLiteral
        literal: 0
        staticType: int
    rightBracket: ]
    staticType: List<int>
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: InvalidType
''');
  }

  test_wrongKind_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  foo ??= 0;
//^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The function 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@function::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@function::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@function::foo
  readType: void Function()
  writeElement: <testLibrary>::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  foo++;
//^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The function 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@function::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@function::foo
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::foo
  readType: void Function()
  writeElement: <testLibrary>::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_increment_prefix() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  ++foo;
//  ^^^
// [diag.undefinedUnqualifiedNameWriteWrongKind] The function 'foo' can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@function::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@function::foo
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  readElement: <testLibrary>::@function::foo
  readType: void Function()
  writeElement: <testLibrary>::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_patternAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  (foo) = 0;
// ^^^
// [diag.patternAssignmentNotLocalVariable] Only local variables can be assigned in pattern assignments.
}
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: foo
      element: <testLibrary>::@function::foo
      matchedValueType: InvalidType
    rightParenthesis: )
    matchedValueType: InvalidType
  equals: =
  expression2: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
  staticType: int
''');
  }
}
