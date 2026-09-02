// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentExpressionResolutionTest);
    defineReflectiveTests(InferenceUpdate3Test);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentExpressionResolutionTest extends PubPackageResolutionTest {
  test_compound_binaryOperator() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic x) {
  x *= 1;
  x /= 1;
  x %= 1;
  x ~/= 1;
  x += 1;
  x -= 1;
  x <<= 1;
  x >>= 1;
  x >>>= 1;
  x &= 1;
  x ^= 1;
  x |= 1;
}
''');

    expect(
      result.findNode.compoundAssignment('x *= 1').binaryOperator,
      BinaryOperator.multiply,
    );
    expect(
      result.findNode.compoundAssignment('x /= 1').binaryOperator,
      BinaryOperator.divide,
    );
    expect(
      result.findNode.compoundAssignment('x %= 1').binaryOperator,
      BinaryOperator.modulo,
    );
    expect(
      result.findNode.compoundAssignment('x ~/= 1').binaryOperator,
      BinaryOperator.truncatingDivide,
    );
    expect(
      result.findNode.compoundAssignment('x += 1').binaryOperator,
      BinaryOperator.add,
    );
    expect(
      result.findNode.compoundAssignment('x -= 1').binaryOperator,
      BinaryOperator.subtract,
    );
    expect(
      result.findNode.compoundAssignment('x <<= 1').binaryOperator,
      BinaryOperator.shiftLeft,
    );
    expect(
      result.findNode.compoundAssignment('x >>= 1').binaryOperator,
      BinaryOperator.shiftRight,
    );
    expect(
      result.findNode.compoundAssignment('x >>>= 1').binaryOperator,
      BinaryOperator.unsignedShiftRight,
    );
    expect(
      result.findNode.compoundAssignment('x &= 1').binaryOperator,
      BinaryOperator.bitwiseAnd,
    );
    expect(
      result.findNode.compoundAssignment('x ^= 1').binaryOperator,
      BinaryOperator.bitwiseXor,
    );
    expect(
      result.findNode.compoundAssignment('x |= 1').binaryOperator,
      BinaryOperator.bitwiseOr,
    );
  }

  test_compound_plus_int_context_int() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int a) {
  a += f();
}
''');

    var node = result.findNode.compoundAssignment('+= f()');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: VariableReadResolution
      element: <testLibrary>::@function::g::@formalParameter::a
      type: int
    write: VariableWriteResolution
      element: <testLibrary>::@function::g::@formalParameter::a
      acceptedType: int
  operator: +=
  value: UnqualifiedFunctionInvocation
    name: f
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@function::f
      invokeType: int Function()
      type: int
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
    typeArgumentTypes
      int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement: <testLibrary>::@function::g::@formalParameter::a
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_complex() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(List<int> a) {
  a[0] += f();
}
''');

    var node = result.findNode.compoundAssignment('+= f()');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::g::@formalParameter::a
      staticType: List<int>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: SubstitutedFormalParameterElementImpl
        baseElement: dart:core::@class::List::@method::[]=::@formalParameter::index
        substitution: {E: int}
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: SubstitutedMethodElementImpl
        baseElement: dart:core::@class::List::@method::[]
        substitution: {E: int}
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: SubstitutedMethodElementImpl
        baseElement: dart:core::@class::List::@method::[]=
        substitution: {E: int}
      invokeType: void Function(int, int)
      acceptedType: int
  operator: +=
  value: UnqualifiedFunctionInvocation
    name: f
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@function::f
      invokeType: int Function()
      type: int
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
    typeArgumentTypes
      int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::g::@formalParameter::a
      staticType: List<int>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: SubstitutedFormalParameterElementImpl
        baseElement: dart:core::@class::List::@method::[]=::@formalParameter::index
        substitution: {E: int}
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: SubstitutedMethodElementImpl
    baseElement: dart:core::@class::List::@method::[]
    substitution: {E: int}
  readType: int
  writeElement: SubstitutedMethodElementImpl
    baseElement: dart:core::@class::List::@method::[]=
    substitution: {E: int}
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_promoted() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(num a) {
  if (a is int) {
    a += f();
  }
}
''');

    var node = result.findNode.compoundAssignment('+= f()');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: VariableReadResolution
      element: <testLibrary>::@function::g::@formalParameter::a
      type: int
    write: VariableWriteResolution
      element: <testLibrary>::@function::g::@formalParameter::a
      acceptedType: num
  operator: +=
  value: UnqualifiedFunctionInvocation
    name: f
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@function::f
      invokeType: int Function()
      type: int
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
    typeArgumentTypes
      int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement: <testLibrary>::@function::g::@formalParameter::a
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_promoted_with_subsequent_demotion() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(num a, bool b) {
  if (a is int) {
    a += b ? f() : 1.0;
    a;
  }
}
''');

    var node = result.findNode.compoundAssignment('+=');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: VariableReadResolution
      element: <testLibrary>::@function::g::@formalParameter::a
      type: int
    write: VariableWriteResolution
      element: <testLibrary>::@function::g::@formalParameter::a
      acceptedType: num
  operator: +=
  value: ConditionalExpression
    condition2: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::g::@formalParameter::b
      staticType: bool
    question: ?
    thenExpression2: UnqualifiedFunctionInvocation
      name: f
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      resolution: ExecutableInvocationResolution
        element: <testLibrary>::@function::f
        invokeType: int Function()
        type: int
      staticType: int
      typeArgumentTypes
        int
    colon: :
    elseExpression2: DoubleLiteral
      literal: 1.0
      staticType: double
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: num
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: num
  staticType: num
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: null
  operator: +=
  rightHandSide: ConditionalExpression
    condition: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::g::@formalParameter::b
      staticType: bool
    question: ?
    thenExpression: MethodInvocation
      methodName: SimpleIdentifier
        token: f
        element: <testLibrary>::@function::f
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
      typeArgumentTypes
        int
    colon: :
    elseExpression: DoubleLiteral
      literal: 1.0
      staticType: double
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: num
  readElement: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement: <testLibrary>::@function::g::@formalParameter::a
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');

    var node2 = result.findNode.simple('a;');
    assertResolvedNodeText(node2, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::g::@formalParameter::a
  staticType: num
''');
  }

  test_dynamicIdentifier_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a += 0;
}
''');

    var node = result.findNode.compoundAssignment('a += 0');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: dynamic
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      acceptedType: dynamic
  operator: +=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: dynamic
  staticType: dynamic
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@function::f::@formalParameter::a
  readType: dynamic
  writeElement: <testLibrary>::@function::f::@formalParameter::a
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_dynamicIdentifier_identifier_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a.foo += 0;
}
''');

    var node = result.findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_dynamicIdentifier_identifier_identifier_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a.foo.bar += 0;
}
''');

    var node = result.findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: dynamic
      period: .
      identifier: SimpleIdentifier
        token: foo
        element: <null>
        staticType: dynamic
      element: <null>
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: bar
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_ifNull_implicitCall_usesUnpromotedWriteType() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  void call() {}
}

void f(Object? x, C c) {
  if (x is Function?) {
    x ??= c;
  }
}
''');

    var node = result.findNode.ifNullAssignment('x ??= c');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: Function?
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: Object?
  operator: ??=
  value: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  staticType: Object
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: Function?
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Object?
  element: <null>
  staticType: Object
''');
  }

  test_ifNull_lubUsedEvenIfItDoesNotSatisfyContext_beforeInferenceUpdate3() async {
    var result = await resolveTestCodeWithDiagnostics('''
// %before-language-feature: inference-update-3
f(Object? o1, Object? o2, List<num> listNum) {
  if (o1 is Iterable<int>? && o2 is Iterable<num>) {
    o2 = (o1 ??= listNum);
  }
}
''');

    var node = result.findNode.ifNullAssignment('o1 ??= listNum');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: o1
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::o1
      type: Iterable<int>?
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::o1
      acceptedType: Object?
  operator: ??=
  value: SimpleIdentifier
    token: listNum
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::listNum
    staticType: List<num>
  staticType: Object
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o1
    element: <testLibrary>::@function::f::@formalParameter::o1
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: listNum
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::listNum
    staticType: List<num>
  readElement: <testLibrary>::@function::f::@formalParameter::o1
  readType: Iterable<int>?
  writeElement: <testLibrary>::@function::f::@formalParameter::o1
  writeType: Object?
  element: <null>
  staticType: Object
''');
  }

  test_ifNull_readType_void() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(void x) {
  x ??= 0;
//  ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    var node = result.findNode.ifNullAssignment('x ??= 0');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: void
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: void
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: void
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: void
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: void
  element: <null>
  staticType: void
''');
  }

  test_importPrefix_deferred_topLevelVariable_simple() async {
    newFile('$testPackageLibPath/a.dart', '''
var v = 0;
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' deferred as prefix;

void f() {
  prefix.v = 0;
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: v
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/a.dart::@setter::v::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@setter::v
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_cascade_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a..[0] += 2;
}
''');

    var node = result.findNode.compoundAssignment('[0] += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: CascadeIndexAssignmentTarget
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    period: ..
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_cascade_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? operator[](int index) => 0;
  operator[]=(int index, num value) {}
}

void f(A a) {
  a..[0] ??= 2;
}
''');

    var node = result.findNode.cascadeSection('..[0] ??= 2');
    assertResolvedNodeText(node, r'''
CascadeSection
  operator: ..
  body: IfNullAssignment
    target: CascadeIndexAssignmentTarget
      leftBracket: [
      index: IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
        staticType: int
      rightBracket: ]
      read: MethodIndexReadResolution
        element: <testLibrary>::@class::A::@method::[]
        invokeType: int? Function(int)
        type: int?
      write: MethodIndexWriteResolution
        element: <testLibrary>::@class::A::@method::[]=
        invokeType: void Function(int, num)
        acceptedType: num
    operator: ??=
    value: IntegerLiteral
      literal: 2
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
      staticType: int
    staticType: int
''');
  }

  test_indexExpression_dynamicTarget_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a[0] += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    read: DynamicIndexReadResolution
      type: dynamic
    write: DynamicIndexWriteResolution
      acceptedType: dynamic
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: dynamic
  staticType: dynamic
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_indexExpression_instance_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2;
}
''');

    var node = result.findNode.compoundAssignment('[0] += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_instance_compound_double_num() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  num operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2.0;
}
''');

    var node = result.findNode.compoundAssignment('[0] += 2.0');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: num Function(int)
      type: num
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: +=
  value: DoubleLiteral
    literal: 2.0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: double
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: double
  staticType: double
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 2.0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: double
  readElement: <testLibrary>::@class::A::@method::[]
  readType: num
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: double
''');
  }

  test_indexExpression_instance_compound_readInvalid() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2;
// ^^^
// [diag.undefinedOperator] The operator '[]' isn't defined for the type 'A'.
}
''');

    var node = result.findNode.compoundAssignment('[0] += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: InvalidIndexReadResolution
      type: InvalidType
      recovery: <null>
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_instance_compound_writeInvalid() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
}

void f(A a) {
  a[0] += 2;
// ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'A'.
}
''');

    var node = result.findNode.compoundAssignment('[0] += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: InvalidIndexWriteResolution
      acceptedType: InvalidType
      recovery: <null>
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_instance_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? operator[](int? index) => 0;
  operator[]=(int? index, num? _) {}
}

void f(A a) {
  a[0] ??= 2;
}
''');

    var node = result.findNode.ifNullAssignment('[0] ??= 2');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int? Function(int?)
      type: int?
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int?, num?)
      acceptedType: num?
  operator: ??=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::_
    staticType: int
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int?
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_nullShorting_assignable() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  B get b;
}
abstract class B {
  operator []=(String s, int i);
}
test(A? a, String s) {
  a?.b[s] = 0;
}
''');

    var node = result.findNode.directAssignment('= 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: PropertyAccess
      target2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    leftBracket: [
    index: SimpleIdentifier
      token: s
      correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::s
      element: <testLibrary>::@function::test::@formalParameter::s
      staticType: String
    rightBracket: ]
    read: <null>
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::B::@method::[]=
      invokeType: void Function(String, int)
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::i
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: PropertyAccess
      target: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    leftBracket: [
    index: SimpleIdentifier
      token: s
      correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::s
      element: <testLibrary>::@function::test::@formalParameter::s
      staticType: String
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::i
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@method::[]=
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_indexExpression_nullShorting_notAssignable() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  B get b;
}
abstract class B {
  operator []=(String s, int i);
}
test(A? a, String s) {
  a?.b[s] = null;
//          ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'int'.
}
''');

    var node = result.findNode.directAssignment('= null');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: PropertyAccess
      target2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    leftBracket: [
    index: SimpleIdentifier
      token: s
      correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::s
      element: <testLibrary>::@function::test::@formalParameter::s
      staticType: String
    rightBracket: ]
    read: <null>
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::B::@method::[]=
      invokeType: void Function(String, int)
      acceptedType: int
  operator: =
  value: NullLiteral
    literal: null
    correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::i
    staticType: Null
  staticType: Null
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: PropertyAccess
      target: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    leftBracket: [
    index: SimpleIdentifier
      token: s
      correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::s
      element: <testLibrary>::@function::test::@formalParameter::s
      staticType: String
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: NullLiteral
    literal: null
    correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::i
    staticType: Null
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@method::[]=
  writeType: int
  element: <null>
  staticType: Null
''');
  }

  test_indexExpression_super_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    super[0] += 2;
  }
}
''');

    var node = result.findNode.compoundAssignment('[0] += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_this_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    this[0] += 2;
  }
}
''');

    var node = result.findNode.compoundAssignment('[0] += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_unresolved1_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int c) {
  a[b] = c;
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
//  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
}
''');

    var node = result.findNode.directAssignment('a[b] = c');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    read: <null>
    write: InvalidIndexWriteResolution
      acceptedType: InvalidType
      recovery: <null>
  operator: =
  value: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved2_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int c) {
  a[b] = c;
// ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'int'.
//  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
}
''');

    var node = result.findNode.directAssignment('a[b] = c');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    read: <null>
    write: InvalidIndexWriteResolution
      acceptedType: InvalidType
      recovery: <null>
  operator: =
  value: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved3_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a, int c) {
  a[b] = c;
//  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
}
''');

    var node = result.findNode.directAssignment('a[b] = c');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    read: <null>
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: =
  value: SimpleIdentifier
    token: c
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::_
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::_
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved_missing_type_parameter_name() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
   void b< extends int>();
//         ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
}
void f(A a) {
  a.b[0] = 0;
//   ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'void Function< extends int>()'.
}
''');
  }

  test_indexExpression_unresolvedTarget_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  a[0] += 1;
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    read: InvalidIndexReadResolution
      type: InvalidType
      recovery: <null>
    write: InvalidIndexWriteResolution
      acceptedType: InvalidType
      recovery: <null>
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
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_left_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super = 0;
//  ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: SuperExpression
      superKeyword: super
      staticType: A
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SuperExpression
    superKeyword: super
    staticType: A
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

  test_notLValue_binaryExpression_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int b, double c) {
  a + b += c;
//^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= c');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: BinaryOperatorInvocation
    leftOperand: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    operator: +
    rightOperand: SimpleIdentifier
      token: b
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: int
    binaryOperator: add
    element: dart:core::@class::num::@method::+
    staticType: int
  leftHandSide(v1): BinaryExpression
    leftOperand: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    operator: +
    rightOperand: SimpleIdentifier
      token: b
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: int
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  operator: +=
  rightHandSide2: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: double
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_binaryExpression_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  1 + 2 = 3;
//^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: BinaryOperatorInvocation
      leftOperand: IntegerLiteral
        literal: 1
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 2
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      binaryOperator: add
      element: dart:core::@class::num::@method::+
      staticType: int
  operator: =
  value: IntegerLiteral
    literal: 3
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
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

  test_notLValue_parenthesized_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int b, double c) {
  (a + b) += c;
//^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= c');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryOperatorInvocation
      leftOperand: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      operator: +
      rightOperand: SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      binaryOperator: add
      element: dart:core::@class::num::@method::+
      staticType: int
    expression(v1): BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      operator: +
      rightOperand: SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      element: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: +=
  rightHandSide2: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: double
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_parenthesized_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, double b) {
  (a + 0) = b;
// ^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'double' isn't assignable to the required type 'int'.
//   ^
// [diag.expectedToken] Expected to find ')'.
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
      matchedValueType: double
    rightParenthesis: )
    matchedValueType: double
  equals: =
  expression2: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  patternTypeSchema: int
  staticType: double
''');
  }

  test_notLValue_parenthesized_simple_beforePatterns() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: patterns
void f(int a, double b) {
  (a + 0) = b;
//^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.directAssignment('= b');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression2: BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 0
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        binaryOperator: add
        element: dart:core::@class::num::@method::+
        staticType: int
      rightParenthesis: )
      staticType: int
  operator: =
  value: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  staticType: double
V1: AssignmentExpression
  leftHandSide: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 0
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: =
  rightHandSide: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: double
''');
  }

  test_notLValue_postfixIncrement_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  x++ += y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PostfixIncrement
    target: UnqualifiedNameAssignmentTarget
      name: x
      read: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::x
        type: num
      write: VariableWriteResolution
        element: <testLibrary>::@function::f::@formalParameter::x
        acceptedType: num
    operator: ++
    element: dart:core::@class::num::@method::+
    operatorResultType: num
    staticType: num
  leftHandSide(v1): PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide2: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_postfixIncrement_compound_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  x++ ??= y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.ifNullAssignment('= y');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: PostfixIncrement
      target: UnqualifiedNameAssignmentTarget
        name: x
        read: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          type: num
        write: VariableWriteResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          acceptedType: num
      operator: ++
      element: dart:core::@class::num::@method::+
      operatorResultType: num
      staticType: num
  operator: ??=
  value: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  staticType: num
V1: AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: num
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: num
''');
  }

  test_notLValue_postfixIncrement_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  x++ = y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.directAssignment('= y');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: PostfixIncrement
      target: UnqualifiedNameAssignmentTarget
        name: x
        read: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          type: num
        write: VariableWriteResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          acceptedType: num
      operator: ++
      element: dart:core::@class::num::@method::+
      operatorResultType: num
      staticType: num
  operator: =
  value: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_prefixIncrement_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  ++x += y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixIncrement
    operator: ++
    target: UnqualifiedNameAssignmentTarget
      name: x
      read: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::x
        type: num
      write: VariableWriteResolution
        element: <testLibrary>::@function::f::@formalParameter::x
        acceptedType: num
    element: dart:core::@class::num::@method::+
    operatorResultType: num
    staticType: num
  leftHandSide(v1): PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide2: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_prefixIncrement_compound_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  ++x ??= y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.ifNullAssignment('= y');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: PrefixIncrement
      operator: ++
      target: UnqualifiedNameAssignmentTarget
        name: x
        read: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          type: num
        write: VariableWriteResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          acceptedType: num
      element: dart:core::@class::num::@method::+
      operatorResultType: num
      staticType: num
  operator: ??=
  value: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  staticType: num
V1: AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: num
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: num
''');
  }

  test_notLValue_prefixIncrement_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  ++x = y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.directAssignment('= y');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: PrefixIncrement
      operator: ++
      target: UnqualifiedNameAssignmentTarget
        name: x
        read: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          type: num
        write: VariableWriteResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          acceptedType: num
      element: dart:core::@class::num::@method::+
      operatorResultType: num
      staticType: num
  operator: =
  value: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_ambiguous_simple() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/b.dart', 'class C {}');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart';
import 'b.dart';
void f() {
  C = 0;
//^
// [diag.ambiguousImport] The name 'C' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.directAssignment('C = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: C
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@class::C
          package:test/b.dart::@class::C
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: C
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: multiplyDefinedElement
    package:test/a.dart::@class::C
    package:test/b.dart::@class::C
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}

void f() {
  C = 0;
//^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.directAssignment('C = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: C
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@class::C
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: C
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_nullAware_context() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int? a) {
  a ??= f();
}
''');

    var node = result.findNode.ifNullAssignment('??= f()');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: VariableReadResolution
      element: <testLibrary>::@function::g::@formalParameter::a
      type: int?
    write: VariableWriteResolution
      element: <testLibrary>::@function::g::@formalParameter::a
      acceptedType: int?
  operator: ??=
  value: UnqualifiedFunctionInvocation
    name: f
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@function::f
      invokeType: int? Function()
      type: int?
    correspondingParameter: <null>
    staticType: int?
    typeArgumentTypes
      int?
  staticType: int?
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: null
  operator: ??=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticInvokeType: int? Function()
    staticType: int?
    typeArgumentTypes
      int?
  readElement: <testLibrary>::@function::g::@formalParameter::a
  readType: int?
  writeElement: <testLibrary>::@function::g::@formalParameter::a
  writeType: int?
  element: <null>
  staticType: int?
''');
  }

  test_prefixedIdentifier_instance_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a.x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_instance_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  a.x ??= 2;
}
''');

    var node = result.findNode.assignment('x ??= 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int?
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instance_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  a.x = 2;
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instanceGetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
}

void f(A a) {
  a.x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_static_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static set x(num _) {}
}

void f() {
  A.x = 2;
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_staticGetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get x => 0;
}

void f() {
  A.x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_topLevel_compound() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get x => 0;
set x(num _) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_typeAlias_static_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get x => 0;
  static set x(int _) {}
}

typedef B = A;

void f() {
  B.x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved1_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int c) {
  a.b = c;
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.assignment('a.b = c');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    period: .
    identifier: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved2_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int c) {
  a.b += c;
//  ^
// [diag.undefinedGetter] The getter 'b' isn't defined for the type 'int'.
// [diag.undefinedSetter] The setter 'b' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.assignment('a.b += c');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_cascade_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a..x += 2;
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: CascadePropertyAssignmentTarget
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_cascade_direct() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  a..x = 2;
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: CascadePropertyAssignmentTarget
    propertyName: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_cascade_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get x => 0;
  set x(num _) {}
}

void f(A a) {
  a..x ??= 2;
}
''');

    var node = result.findNode.ifNullAssignment('x ??= 2');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: CascadePropertyAssignmentTarget
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: ??=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int?
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_dynamic_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  (a).x = 2;
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    operator: .
    propertyName: x
    read: <null>
    write: DynamicPropertyWriteResolution
      acceptedType: dynamic
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_forwardingStub() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
}
abstract class I<T> {
  T x = throw 0;
}
class B extends A implements I<int> {}
main() {
  new B().x = 1;
}
''');

    var node = result.findNode.assignment('x = 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      keyword: new
      constructorName: ConstructorName
        type: NamedType
          name: B
          element: <testLibrary>::@class::B
          type: B
        element: <testLibrary>::@class::B::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_indexExpression_compound() async {
    var result = await resolveTestCode(r'''
class A {
  B operator [](int index) => B();
}

class B {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a[0].x += 2;
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ReceiverIndexExpression
      receiver: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      leftBracket: [
      index: IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
        staticType: int
      rightBracket: ]
      resolution: MethodIndexReadResolution
        element: <testLibrary>::@class::A::@method::[]
        invokeType: B Function(int)
        type: B
      staticType: B
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::B::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::B::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: IndexExpression
      target: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      leftBracket: [
      index: IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
        staticType: int
      rightBracket: ]
      element: <testLibrary>::@class::A::@method::[]
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::B::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::B::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  (a).x += 2;
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_fromMixins_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
mixin M1 {
  int get x => 0;
  set x(num _) {}
}

mixin M2 {
  int get x => 0;
  set x(num _) {}
}

class C with M1, M2 {
}

void f(C c) {
  (c).x += 2;
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: c
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@mixin::M2::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@mixin::M2::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@mixin::M2::@getter::x
  readType: int
  writeElement: <testLibrary>::@mixin::M2::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  (a).x ??= 2;
}
''');

    var node = result.findNode.ifNullAssignment('x ??= 2');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num?
  operator: ??=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int?
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_instance_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  (a).x = 2;
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_never_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never a) {
  (a).x = 2;
//^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//        ^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Never
      rightParenthesis: )
      staticType: Never
    operator: .
    propertyName: x
    read: <null>
    write: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: Never
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Never
      rightParenthesis: )
      staticType: Never
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: Never
''');
  }

  test_propertyAccess_nullShorting_assignable() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  B get b;
}
abstract class B {
  set setter(int i);
}
test(A? a) {
  a?.b.setter = 0;
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: PropertyAccess
      target2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: setter
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::B::@setter::setter::@formalParameter::i
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@setter::setter
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_propertyAccess_nullShorting_notAssignable() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  B get b;
}
abstract class B {
  set setter(int i);
}
test(A? a) {
  a?.b.setter = null;
//              ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'int'.
}
''');

    var node = result.findNode.assignment('= null');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: PropertyAccess
      target2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: setter
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: NullLiteral
    literal: null
    correspondingParameter: <testLibrary>::@class::B::@setter::setter::@formalParameter::i
    staticType: Null
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@setter::setter
  writeType: int
  element: <null>
  staticType: Null
''');
  }

  test_propertyAccess_parenthesized_classGetter_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
}

void f(A a) {
  (a).x += 2;
//    ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
}
''');

    var node = result.findNode.compoundAssignment('(a).x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@class::A::@getter::x
      recovery: <null>
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@getter::x
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_parenthesized_classSetter_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(int _) {}
}

void f(A a) {
  (a).x += 2;
//    ^
// [diag.undefinedGetter] The getter 'x' isn't defined for the type 'A'.
}
''');

    var node = result.findNode.compoundAssignment('(a).x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: x
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: <testLibrary>::@class::A::@setter::x
      recovery: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: int
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_parenthesized_dynamic_compound() async {
    var result = await resolveTestCode(r'''
void f(dynamic a) {
  (a).x += 2;
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    operator: .
    propertyName: x
    read: DynamicPropertyReadResolution
      type: dynamic
    write: DynamicPropertyWriteResolution
      acceptedType: dynamic
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: dynamic
  staticType: dynamic
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_propertyAccess_parenthesized_dynamic_ifNull() async {
    var result = await resolveTestCode(r'''
void f(dynamic a) {
  (a).x ??= 2;
}
''');

    var node = result.findNode.ifNullAssignment('x ??= 2');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    operator: .
    propertyName: x
    read: DynamicPropertyReadResolution
      type: dynamic
    write: DynamicPropertyWriteResolution
      acceptedType: dynamic
  operator: ??=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: dynamic
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_propertyAccess_parenthesized_functionCall_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(void Function() a) {
  (a).call ??= () {};
//             ^^^^^
// [diag.deadCode] Dead code.
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.ifNullAssignment('call ??= () {}');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: void Function()
      rightParenthesis: )
      staticType: void Function()
    operator: .
    propertyName: call
    read: FunctionCallTearOffResolution
      type: void Function()
      associatedFunctionType: void Function()
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: ??=
  value: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> null@null
      element: null@null
        type: Never Function()
    correspondingParameter: <null>
    staticType: Never Function()
  staticType: void Function()
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: void Function()
      rightParenthesis: )
      staticType: void Function()
    operator: .
    propertyName: SimpleIdentifier
      token: call
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> null@null
      element: null@null
        type: Never Function()
    correspondingParameter: <null>
    staticType: Never Function()
  readElement: <null>
  readType: void Function()
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: void Function()
''');
  }

  test_propertyAccess_parenthesized_method_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

void f(A a) {
  (a).foo ??= () {};
//    ^^^
// [diag.assignmentToMethod] Methods can't be assigned a value.
//            ^^^^^
// [diag.deadCode] Dead code.
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= () {}');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::A::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@class::A::@method::foo
      recovery: <null>
  operator: ??=
  value: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> null@null
      element: null@null
        type: Never Function()
    correspondingParameter: <null>
    staticType: Never Function()
  staticType: void Function()
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> null@null
      element: null@null
        type: Never Function()
    correspondingParameter: <null>
    staticType: Never Function()
  readElement: <testLibrary>::@class::A::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::A::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: void Function()
''');
  }

  test_propertyAccess_parenthesized_method_ifNull_substituted() async {
    var result = await resolveTestCode(r'''
class A<T> {
  void foo(T value) {}
}

void f(A<int> a) {
  (a).foo ??= 0;
}
''');

    var node = result.findNode.ifNullAssignment('foo ??=');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A<int>
      rightParenthesis: )
      staticType: A<int>
    operator: .
    propertyName: foo
    read: ExecutableTearOffResolution
      element: SubstitutedMethodElementImpl
        baseElement: <testLibrary>::@class::A::@method::foo
        substitution: {T: int}
      type: void Function(int)
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: SubstitutedMethodElementImpl
          baseElement: <testLibrary>::@class::A::@method::foo
          substitution: {T: int}
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: Object
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A<int>
      rightParenthesis: )
      staticType: A<int>
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::A::@method::foo
    substitution: {T: int}
  readType: void Function(int)
  writeElement: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::A::@method::foo
    substitution: {T: int}
  writeType: InvalidType
  element: <null>
  staticType: Object
''');
  }

  test_propertyAccess_parenthesized_never_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never a) {
  (a).x += 2;
//^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//         ^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Never
      rightParenthesis: )
      staticType: Never
    operator: .
    propertyName: x
    read: <null>
    write: <null>
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: Never
  staticType: Never
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Never
      rightParenthesis: )
      staticType: Never
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: Never
''');
  }

  test_propertyAccess_parenthesized_nullAware() async {
    var result = await resolveTestCode(r'''
class A {
  num get x => 0;
  set x(num value) {}
}
class B {
  num? get x => 0;
  set x(num value) {}
}

void f(A? a, B? b) {
  (a)?.x = 1;
  (a)?.x += 2;
  (b)?.x ??= 3;
}
''');

    var direct = result.findNode.directAssignment('(a)?.x = 1');
    assertResolvedNodeText(direct, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A?
      rightParenthesis: )
      staticType: A?
    operator: ?.
    propertyName: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::value
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A?
      rightParenthesis: )
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int?
''');

    var compound = result.findNode.compoundAssignment('(a)?.x += 2');
    assertResolvedNodeText(compound, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A?
      rightParenthesis: )
      staticType: A?
    operator: ?.
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: num Function()
      type: num
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: num
  staticType: num?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A?
      rightParenthesis: )
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: num
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num?
''');

    var ifNull = result.findNode.ifNullAssignment('(b)?.x ??= 3');
    assertResolvedNodeText(ifNull, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: B?
      rightParenthesis: )
      staticType: B?
    operator: ?.
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::B::@getter::x
      invokeType: num? Function()
      type: num?
    write: SetterInvocationResolution
      element: <testLibrary>::@class::B::@setter::x
      acceptedType: num
  operator: ??=
  value: IntegerLiteral
    literal: 3
    correspondingParameter: <testLibrary>::@class::B::@setter::x::@formalParameter::value
    staticType: int
  staticType: num?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: B?
      rightParenthesis: )
      staticType: B?
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 3
    correspondingParameter: <testLibrary>::@class::B::@setter::x::@formalParameter::value
    staticType: int
  readElement: <testLibrary>::@class::B::@getter::x
  readType: num?
  writeElement: <testLibrary>::@class::B::@setter::x
  writeType: num
  element: <null>
  staticType: num?
''');
  }

  test_propertyAccess_parenthesized_nullAware_null() async {
    var result = await resolveTestCode(r'''
void f(Null a) {
  (a)?.x = 1;
  (a)?.x += 2;
  (a)?.x ??= 3;
}
''');

    var direct = result.findNode.directAssignment('(a)?.x = 1');
    assertResolvedNodeText(direct, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Null
      rightParenthesis: )
      staticType: Null
    operator: ?.
    propertyName: x
    read: <null>
    write: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: Never?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Null
      rightParenthesis: )
      staticType: Null
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: Never?
''');

    var compound = result.findNode.compoundAssignment('(a)?.x += 2');
    assertResolvedNodeText(compound, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Null
      rightParenthesis: )
      staticType: Null
    operator: ?.
    propertyName: x
    read: <null>
    write: <null>
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: Never
  staticType: Never?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Null
      rightParenthesis: )
      staticType: Null
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: Never?
''');

    var ifNull = result.findNode.ifNullAssignment('(a)?.x ??= 3');
    assertResolvedNodeText(ifNull, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Null
      rightParenthesis: )
      staticType: Null
    operator: ?.
    propertyName: x
    read: <null>
    write: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 3
    correspondingParameter: <null>
    staticType: int
  staticType: Never?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: Null
      rightParenthesis: )
      staticType: Null
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 3
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: Never?
''');
  }

  test_propertyAccess_parenthesized_propertyAccess_simple() async {
    var result = await resolveTestCode(r'''
class A {
  B get x => B();
}

class B {
  set y(int _) {}
}

void f(A a) {
  (a).x.y = 0;
}
''');

    var node = result.findNode.directAssignment('y = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ReceiverPropertyExtraction
      receiver: ParenthesizedExpression
        leftParenthesis: (
        expression2: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
        rightParenthesis: )
        staticType: A
      operator: .
      propertyName: x
      resolution: GetterInvocationResolution
        element: <testLibrary>::@class::A::@getter::x
        invokeType: B Function()
        type: B
      staticType: B
    operator: .
    propertyName: y
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::B::@setter::y
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::B::@setter::y::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: PropertyAccess
      target: ParenthesizedExpression
        leftParenthesis: (
        expression: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
        rightParenthesis: )
        staticType: A
      operator: .
      propertyName: SimpleIdentifier
        token: x
        element: <testLibrary>::@class::A::@getter::x
        staticType: B
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: y
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::B::@setter::y::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@setter::y
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_parenthesized_recordField_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int x}) r) {
  (r).x ??= 0;
//    ^
// [diag.undefinedSetter] The setter 'x' isn't defined for the type '({int x})'.
//          ^^
// [diag.deadCode] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.ifNullAssignment('x ??= 0');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: r
        element: <testLibrary>::@function::f::@formalParameter::r
        staticType: ({int x})
      rightParenthesis: )
      staticType: ({int x})
    operator: .
    propertyName: x
    read: RecordFieldReadResolution
      type: int
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: r
        element: <testLibrary>::@function::f::@formalParameter::r
        staticType: ({int x})
      rightParenthesis: )
      staticType: ({int x})
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_parenthesized_unresolved_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int c) {
  (a).b += c;
//    ^
// [diag.undefinedGetter] The getter 'b' isn't defined for the type 'int'.
// [diag.undefinedSetter] The setter 'b' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.compoundAssignment('(a).b += c');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      rightParenthesis: )
      staticType: int
    operator: .
    propertyName: b
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: +=
  value: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      rightParenthesis: )
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FFFF_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type '({int bar})'.
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({int bar})'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FFFF_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({int bar})'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FFFT_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type '({int bar})'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@extension::E::@setter::foo
  readType: InvalidType
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FFFT_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo = 0;
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FTFF_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  int get foo => 0;
}

void f(({int bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'foo' in class 'E'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FTFF_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  int get foo => 0;
}

void f(({int bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'foo' in class 'E'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FTFT_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo += 0;
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FTFT_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo = 0;
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TFFF_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo, String bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TFFF_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo, String bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TFFT_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TFFT_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TTFF_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TTFF_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TTFT_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TTFT_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FFFF_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$4 += 0;
//  ^^
// [diag.undefinedGetter] The getter '$4' isn't defined for the type '(int, String)'.
// [diag.undefinedSetter] The setter '$4' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $4
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FFFF_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$4 = 0;
//  ^^
// [diag.undefinedSetter] The setter '$4' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $4
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FTFF_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  int get $3 => 0;
}

void f((int, String) r) {
  r.$3 += 0;
//  ^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named '$3' in class 'E'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $3
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::$3
  readType: int
  writeElement: <testLibrary>::@extension::E::@getter::$3
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FTFF_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  int get $3 => 0;
}

void f((int, String) r) {
  r.$3 = 0;
//  ^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named '$3' in class 'E'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $3
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@getter::$3
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_TFFF_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$1 += 0;
//  ^^
// [diag.undefinedSetter] The setter '$1' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_TFFF_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$1 = 0;
//  ^^
// [diag.undefinedSetter] The setter '$1' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_positional_TFFT_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  set $1(int _) {}
}

void f((int, String) r) {
  r.$1 += 0;
//  ^^
// [diag.undefinedSetter] The setter '$1' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_positional_TFFT_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  set $1(int _) {}
}

void f((int, String) r) {
  r.$1 = 0;
//  ^^
// [diag.undefinedSetter] The setter '$1' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  test_propertyAccess_super_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    super.x += 2;
  }
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_this_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}

  void f() {
    this.x += 2;
  }
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_this_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get x => 0;
  set x(num _) {}

  void f() {
    this.x ??= 2;
  }
}
''');

    var node = result.findNode.ifNullAssignment('x ??= 2');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: ??=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int?
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_this_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}

  void f() {
    this.x = 2;
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_unresolved1_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int c) {
  (a).b = c;
// ^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.directAssignment('(a).b = c');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <null>
        staticType: InvalidType
      rightParenthesis: )
      staticType: InvalidType
    operator: .
    propertyName: b
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: =
  value: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <null>
        staticType: InvalidType
      rightParenthesis: )
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_unresolved2_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int c) {
  (a).b = c;
//    ^
// [diag.undefinedSetter] The setter 'b' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.directAssignment('(a).b = c');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      rightParenthesis: )
      staticType: int
    operator: .
    propertyName: b
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: =
  value: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      rightParenthesis: )
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_propertyAssignmentTarget_explicitInstanceCreation_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x = 0;
}

void f() {
  new C()?.x = 0;
//       ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ConstructorInvocation
      keyword: new
      constructorReference: ConstructorReference2
        typeReference: ConstructorTypeReference
          name: C
          element: <testLibrary>::@class::C
          type: C
        element: <testLibrary>::@class::C::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: C
    operator: ?.
    propertyName: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::x
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      keyword: new
      constructorName: ConstructorName
        type: NamedType
          name: C
          element: <testLibrary>::@class::C
          type: C
        element: <testLibrary>::@class::C::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: C
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_propertyAssignmentTarget_stringLiteral_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  set x(int value) {}
}

void f() {
  'a'?.x = 0;
//   ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleStringLiteral
      literal: 'a'
    operator: ?.
    propertyName: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::x
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@setter::x::@formalParameter::value
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleStringLiteral
      literal: 'a'
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::x
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_propertyAssignmentTarget_this_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x = 0;

  void f() {
    this?.x = 0;
//      ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: C
    operator: ?.
    propertyName: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::x
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: C
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_receiverIndexAssignmentTarget_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a[0] = 2;
}
''');

    var node = result.findNode.directAssignment('[0] = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    read: <null>
    write: DynamicIndexWriteResolution
      acceptedType: dynamic
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: int
''');
  }

  test_receiverIndexAssignmentTarget_invalid() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  a[0] = 2;
// ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.directAssignment('[0] = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    read: <null>
    write: InvalidIndexWriteResolution
      acceptedType: InvalidType
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
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

  test_receiverIndexAssignmentTarget_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] = 2;
}
''');

    var node = result.findNode.directAssignment('[0] = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: <null>
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_right_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f(Object a) {
    a = super;
//      ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.directAssignment('a = super');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: <null>
    write: VariableWriteResolution
      element: <testLibrary>::@class::A::@method::f::@formalParameter::a
      acceptedType: Object
  operator: =
  value: SuperExpression
    superKeyword: super
    staticType: A
  staticType: A
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@class::A::@method::f::@formalParameter::a
    staticType: null
  operator: =
  rightHandSide: SuperExpression
    superKeyword: super
    staticType: A
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::f::@formalParameter::a
  writeType: Object
  element: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_fieldInstance_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_fieldInstance_substituted_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  late T x;
}

class B extends A<num> {
  void f() {
    x = 2;
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: SubstitutedSetterElementImpl
        baseElement: <testLibrary>::@class::A::@setter::x
        substitution: {T: num}
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: SubstitutedFormalParameterElementImpl
      baseElement: <testLibrary>::@class::A::@setter::x::@formalParameter::value
      substitution: {T: num}
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: SubstitutedFormalParameterElementImpl
      baseElement: <testLibrary>::@class::A::@setter::x::@formalParameter::value
      substitution: {T: num}
    staticType: int
  readElement: <null>
  readType: null
  writeElement: SubstitutedSetterElementImpl
    baseElement: <testLibrary>::@class::A::@setter::x
    substitution: {T: num}
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_fieldStatic_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterInstance_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  num get x => 0;

  void f() {
    x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'C'.
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@class::C::@getter::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterStatic_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static num get x => 0;

  void f() {
    x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'C'.
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@class::C::@getter::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterTopLevel_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get x => 0;

void f() {
  x = 2;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@getter::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_hasSuperSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:math' as x;

class A {
  var x;
}

class B extends A {
  void f() {
    x = 2;
//  ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'x' refers to an import prefix, so it must be followed by '.'.
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibraryFragment>::@prefix::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibraryFragment>::@prefix::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:math' as x;

main() {
  x = 2;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'x' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibraryFragment>::@prefix::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibraryFragment>::@prefix::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariable_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x += 3;
}
''');

    var node = result.findNode.compoundAssignment('x += 3');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: x@51
      type: num
    write: VariableWriteResolution
      element: x@51
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 3
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: num
  staticType: num
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: x@51
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: x@51
  readType: num
  writeElement: x@51
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_simpleIdentifier_localVariable_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x = 2;
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: VariableWriteResolution
      element: x@51
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: x@51
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@51
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableConst_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  // ignore:unused_local_variable
  const num x = 1;
  x = 2;
//^
// [diag.assignmentToConst] Constant variables can't be assigned a value after initialization.
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: VariableWriteResolution
      element: x@57
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@57
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableFinal_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  // ignore:unused_local_variable
  final num x = 1;
  x = 2;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: VariableWriteResolution
      element: x@57
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@57
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num? x) {
  x ??= 0;
}
''');

    var node = result.findNode.ifNullAssignment('x ??=');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: num?
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: num?
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: num
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: num?
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: num?
  element: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull2() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {}
class C extends A {}

void f(B? x) {
  x ??= C();
//      ^^^
// [diag.invalidAssignment] A value of type 'C' can't be assigned to a variable of type 'B?'.
}
''');

    var node = result.findNode.ifNullAssignment('x ??=');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: B?
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: B?
  operator: ??=
  value: ConstructorInvocation
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticType: C
  staticType: A
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticType: C
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: B?
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: B?
  element: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull_notAssignableType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(double? a, int b) {
  a ??= b;
//      ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'double?'.
}
''');

    var node = result.findNode.ifNullAssignment('a ??=');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: double?
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      acceptedType: double?
  operator: ??=
  value: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  staticType: num
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  readElement: <testLibrary>::@function::f::@formalParameter::a
  readType: double?
  writeElement: <testLibrary>::@function::f::@formalParameter::a
  writeType: double?
  element: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_double() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x += 1.2;
//     ^^^
// [diag.invalidAssignment] A value of type 'double' can't be assigned to a variable of type 'int'.
  x -= 1.2;
//     ^^^
// [diag.invalidAssignment] A value of type 'double' can't be assigned to a variable of type 'int'.
  x *= 1.2;
//     ^^^
// [diag.invalidAssignment] A value of type 'double' can't be assigned to a variable of type 'int'.
  x %= 1.2;
//     ^^^
// [diag.invalidAssignment] A value of type 'double' can't be assigned to a variable of type 'int'.
}
''');
    assertType(result.findNode.compoundAssignment('+='), 'double');
    assertType(result.findNode.compoundAssignment('-='), 'double');
    assertType(result.findNode.compoundAssignment('*='), 'double');
    assertType(result.findNode.compoundAssignment('%='), 'double');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x += 1;
  x -= 1;
  x *= 1;
  x ~/= 1;
  x %= 1;
}
''');
    assertType(result.findNode.compoundAssignment('+='), 'int');
    assertType(result.findNode.compoundAssignment('-='), 'int');
    assertType(result.findNode.compoundAssignment('*='), 'int');
    assertType(result.findNode.compoundAssignment('~/='), 'int');
    assertType(result.findNode.compoundAssignment('%='), 'int');
  }

  test_simpleIdentifier_parameter_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  x = 2;
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_parameter_simple_context() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x is double) {
    x = 1;
  }
}
''');

    var node = result.findNode.directAssignment('x = 1');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: Object
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: double
  staticType: double
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: double
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Object
  element: <null>
  staticType: double
''');
  }

  test_simpleIdentifier_parameter_simple_notAssignableType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x = true;
//    ^^^^
// [diag.invalidAssignment] A value of type 'bool' can't be assigned to a variable of type 'int'.
}
''');

    var node = result.findNode.directAssignment('x = true');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: int
  operator: =
  value: BooleanLiteral
    literal: true
    correspondingParameter: <null>
    staticType: bool
  staticType: bool
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    correspondingParameter: <null>
    staticType: bool
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_parameterFinal_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
// %before-language-feature: primary-constructors
void f(final int x) {
  x = 2;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticGetter_superSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set x(num _) {}
}

class B extends A {
  static int get x => 1;
//               ^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'x' and have instance member 'A.x' with the same name.

  void f() {
    x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'B'.
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@class::B::@getter::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticMethod_superSetter_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set x(num _) {}
}

class B extends A {
  static void x() {}
//            ^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'x' and have instance member 'A.x' with the same name.

  void f() {
    x ??= 2;
//  ^
// [diag.assignmentToMethod] Methods can't be assigned a value.
//        ^^
// [diag.deadCode] Dead code.
//        ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  }
}
''');

    var node = result.findNode.ifNullAssignment('x ??= 2');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::B::@method::x
      type: void Function()
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@class::B::@method::x
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: Object
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::B::@method::x
  readType: void Function()
  writeElement: <testLibrary>::@class::B::@method::x
  writeType: InvalidType
  element: <null>
  staticType: Object
''');
  }

  test_simpleIdentifier_staticMethod_superSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set x(num _) {}
}

class B extends A {
  static void x() {}
//            ^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'x' and have instance member 'A.x' with the same name.

  void f() {
    x = 2;
//  ^
// [diag.assignmentToMethod] Methods can't be assigned a value.
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@class::B::@method::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@method::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_superSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

class B extends A {
  void f() {
    x = 2;
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_synthetic_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(int y) {
  = y;
//^
// [diag.missingIdentifier] Expected an identifier.
}
''');

    var node = result.findNode.directAssignment('= y');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: <empty> <synthetic>
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: =
  value: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: <empty> <synthetic>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_superGetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int x = 0;
}

class B extends A {
  int get x => 1;

  void f() {
    x = 2;
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int get x => 0;
  set x(num _) {}

  void f() {
    x += 2;
  }
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_compound_rhsContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
T valueOfType<T>() => throw 0;

class C {
  int get x => 0;
  set x(num _) {}

  void f() {
    x += valueOfType();
  }
}
''');

    var node = result.findNode.compoundAssignment('x += valueOfType()');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::x
      acceptedType: num
  operator: +=
  value: UnqualifiedFunctionInvocation
    name: valueOfType
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@function::valueOfType
      invokeType: num Function()
      type: num
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: num
    typeArgumentTypes
      num
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: num
  staticType: num
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: valueOfType
      element: <testLibrary>::@function::valueOfType
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticInvokeType: num Function()
    staticType: num
    typeArgumentTypes
      num
  readElement: <testLibrary>::@class::C::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_fromMixins_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
mixin M1 {
  int get x => 0;
  set x(num _) {}
}

mixin M2 {
  int get x => 0;
  set x(num _) {}
}

class C with M1, M2 {
  void f() {
    x += 2;
  }
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@mixin::M2::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@mixin::M2::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@mixin::M2::@getter::x
  readType: int
  writeElement: <testLibrary>::@mixin::M2::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int? get x => 0;
  set x(num? _) {}

  void f() {
    x ??= 2;
  }
}
''');

    var node = result.findNode.ifNullAssignment('x ??= 2');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::x
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::x
      acceptedType: num?
  operator: ??=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::_
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::x
  readType: int?
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_superSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set x(num _) {}
}

int get x => 1;

class B extends A {

  void f() {
    x = 2;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  }
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@getter::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get x => 0;
set x(num _) {}

void f() {
  x += 2;
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound_ifNull2() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  x ??= C();
//      ^^^
// [diag.invalidAssignment] A value of type 'C' can't be assigned to a variable of type 'B?'.
}

class A {}
class B extends A {}
class C extends A {}

B? get x => B();
set x(B? _) {}
''');

    var node = result.findNode.ifNullAssignment('x ??=');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      invokeType: B? Function()
      type: B?
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: B?
  operator: ??=
  value: ConstructorInvocation
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <testLibrary>::@setter::x::@formalParameter::_
    staticType: C
  staticType: A
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <testLibrary>::@setter::x::@formalParameter::_
    staticType: C
  readElement: <testLibrary>::@getter::x
  readType: B?
  writeElement: <testLibrary>::@setter::x
  writeType: B?
  element: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_topGetter_topSetter_fromClass_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get x => 0;
set x(num _) {}

class A {
  void f() {
    x += 2;
  }
}
''');

    var node = result.findNode.compoundAssignment('x += 2');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: num
  operator: +=
  value: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelFunction_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo(int value) {}

void f() {
  foo += 0;
//^^^
// [diag.assignmentToFunction] Functions can't be assigned a value.
//    ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'void Function(int)'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 0');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@function::foo
      type: void Function(int)
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@function::foo
      recovery: <null>
  operator: +=
  value: IntegerLiteral
    literal: 0
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@function::foo
  readType: void Function(int)
  writeElement: <testLibrary>::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_topLevelFunction_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo(int value) {}

void f() {
  foo = 0;
//^^^
// [diag.assignmentToFunction] Functions can't be assigned a value.
}
''');

    var node = result.findNode.directAssignment('foo = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@function::foo
      recovery: <null>
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

  test_simpleIdentifier_topLevelVariable_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
num x = 0;

void f() {
  x = 2;
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: num
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@setter::x::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelVariable_simple_notAssignableType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int x = 0;

void f() {
  x = true;
//    ^^^^
// [diag.invalidAssignment] A value of type 'bool' can't be assigned to a variable of type 'int'.
}
''');

    var node = result.findNode.directAssignment('x = true');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: int
  operator: =
  value: BooleanLiteral
    literal: true
    correspondingParameter: <testLibrary>::@setter::x::@formalParameter::value
    staticType: bool
  staticType: bool
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    correspondingParameter: <testLibrary>::@setter::x::@formalParameter::value
    staticType: bool
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@setter::x
  writeType: int
  element: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_topLevelVariableFinal_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final num x = 0;

void f() {
  x = 2;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');

    var node = result.findNode.directAssignment('x = 2');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: <testLibrary>::@getter::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_typeLiteral_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int += 3;
//^^^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.compoundAssignment('int += 3');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: int
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: dart:core::@class::int
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: dart:core::@class::int
      recovery: <null>
  operator: +=
  value: IntegerLiteral
    literal: 3
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    correspondingParameter: <null>
    staticType: int
  readElement: dart:core::@class::int
  readType: InvalidType
  writeElement: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_typeLiteral_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int = 0;
//^^^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.directAssignment('int = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: int
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: dart:core::@class::int
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_unresolved_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  x += 1;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');

    var node = result.findNode.compoundAssignment('x += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
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
    token: x
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_unresolved_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  x = a;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');

    var node = result.findNode.directAssignment('x = a');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: =
  value: SimpleIdentifier
    token: a
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }
}

@reflectiveTest
class InferenceUpdate3Test extends PubPackageResolutionTest {
  test_ifNull_contextIsConvertedToATypeUsingGreatestClosure() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
class B1<T> extends A {}
class B2<T> extends A {}
class C1<T> implements B1<T>, B2<T> {}
class C2<T> implements B1<T>, B2<T> {}
void contextB1<T>(B1<T> b1) {}
f(Object? o, C2<double> c2) {
  if (o is C1<int>?) {
    contextB1(o ??= c2);
  }
}
''');

    var node = result.findNode.ifNullAssignment('o ??= c2');
    assertResolvedNodeText(node, r'''IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: o
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::o
      type: C1<int>?
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::o
      acceptedType: Object?
  operator: ??=
  value: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2<double>
  correspondingParameter: SubstitutedFormalParameterElementImpl
    baseElement: <testLibrary>::@function::contextB1::@formalParameter::b1
    substitution: {T: Object?}
  staticType: B1<Object?>
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o
    element: <testLibrary>::@function::f::@formalParameter::o
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2<double>
  correspondingParameter: SubstitutedFormalParameterElementImpl
    baseElement: <testLibrary>::@function::contextB1::@formalParameter::b1
    substitution: {T: Object?}
  readElement: <testLibrary>::@function::f::@formalParameter::o
  readType: C1<int>?
  writeElement: <testLibrary>::@function::f::@formalParameter::o
  writeType: Object?
  element: <null>
  staticType: B1<Object?>
''');
  }

  test_ifNull_contextNotUsedIfLhsDoesNotSatisfyContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
f(Object? o1, Object? o2, int? i) {
  if (o1 is int? && o2 is double?) {
    o1 = (o2 ??= i);
  }
}
''');

    var node = result.findNode.ifNullAssignment('o2 ??= i');
    assertResolvedNodeText(node, r'''IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: o2
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::o2
      type: double?
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::o2
      acceptedType: Object?
  operator: ??=
  value: SimpleIdentifier
    token: i
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::i
    staticType: int?
  staticType: num?
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o2
    element: <testLibrary>::@function::f::@formalParameter::o2
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: i
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::i
    staticType: int?
  readElement: <testLibrary>::@function::f::@formalParameter::o2
  readType: double?
  writeElement: <testLibrary>::@function::f::@formalParameter::o2
  writeType: Object?
  element: <null>
  staticType: num?
''');
  }

  test_ifNull_contextUsedInsteadOfLubIfLubDoesNotSatisfyContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
void contextB1(B1 b1) {}
f(Object? o, C2 c2) {
  if (o is C1?) {
    contextB1(o ??= c2);
  }
}
''');

    var node = result.findNode.ifNullAssignment('o ??= c2');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: o
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::o
      type: C1?
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::o
      acceptedType: Object?
  operator: ??=
  value: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2
  correspondingParameter: <testLibrary>::@function::contextB1::@formalParameter::b1
  staticType: B1
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o
    element: <testLibrary>::@function::f::@formalParameter::o
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2
  correspondingParameter: <testLibrary>::@function::contextB1::@formalParameter::b1
  readElement: <testLibrary>::@function::f::@formalParameter::o
  readType: C1?
  writeElement: <testLibrary>::@function::f::@formalParameter::o
  writeType: Object?
  element: <null>
  staticType: B1
''');
  }
}
