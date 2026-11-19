// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfElementResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IfElementResolutionTest extends PubPackageResolutionTest {
  test_caseClause() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  [if (x case 0) 1 else 2];
}
''');

    var node = result.findNode.ifElement('if');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: Object
    staticType: Object
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression2: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 1
    staticType: int
  elseKeyword: else
  elseElement2: IntegerLiteral
    literal: 2
    staticType: int
''');
  }

  test_caseClause_pattern_constant_list_closure() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(x) => [if (x case const [() {}]) 0];
//                         ^^^^^
// [diag.constantPatternWithNonConstantExpression] The expression of a constant pattern must be a valid constant.
''');

    var node = result.findNode.ifElement('if (x');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: dynamic
    staticType: dynamic
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        constKeyword: const
        expression2: ListLiteral
          leftBracket: [
          elements2
            FunctionExpression
              parameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
              body: BlockFunctionBody
                block: Block
                  leftBracket: {
                  rightBracket: }
              declaredFragment: <testLibraryFragment> null@null
                element: null@null
                  type: Null Function()
              staticType: Null Function()
          rightBracket: ]
          staticType: List<Null Function()>
        matchedValueType: dynamic
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_caseClause_pattern_constant_list_forElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(x) => [if (x case const [for (var i in []) i]) 0];
//                         ^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');

    var node = result.findNode.ifElement('if (x');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: dynamic
    staticType: dynamic
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        constKeyword: const
        expression2: ListLiteral
          leftBracket: [
          elements2
            ForElement
              forKeyword: for
              leftParenthesis: (
              forLoopParts: ForEachPartsWithDeclaration
                loopVariable: DeclaredIdentifier
                  keyword: var
                  name: i
                  declaredFragment: isPublic i@36
                    element: hasImplicitType isPublic
                      type: dynamic
                inKeyword: in
                iterable2: ListLiteral
                  leftBracket: [
                  rightBracket: ]
                  staticType: List<dynamic>
              rightParenthesis: )
              body2: UnqualifiedNameExpression
                name: i
                resolution: VariableReadResolution
                  element: i@36
                  type: dynamic
                staticType: dynamic
              body(v1): SimpleIdentifier
                token: i
                element: i@36
                staticType: dynamic
          rightBracket: ]
          staticType: List<dynamic>
        matchedValueType: dynamic
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_caseClause_pattern_constant_parenthesized_closure() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(x) => [if (x case const (() {})) 0];
//                         ^^^^^
// [diag.constantPatternWithNonConstantExpression] The expression of a constant pattern must be a valid constant.
''');

    var node = result.findNode.ifElement('if (x');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: dynamic
    staticType: dynamic
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        constKeyword: const
        expression2: ParenthesizedExpression
          leftParenthesis: (
          expression2: FunctionExpression
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
            declaredFragment: <testLibraryFragment> null@null
              element: null@null
                type: Null Function()
            staticType: Null Function()
          rightParenthesis: )
          staticType: Null Function()
        matchedValueType: dynamic
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_caseClause_pattern_map_key_closure() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(x) => [if (x case {() {}: 0}) 0];
//                   ^^^^^
// [diag.nonConstantMapPatternKey] Key expressions in map patterns must be constants.
''');

    var node = result.findNode.ifElement('if (x');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: dynamic
    staticType: dynamic
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: MapPattern
        leftBracket: {
        elements
          MapPatternEntry
            key2: FunctionExpression
              parameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
              body: BlockFunctionBody
                block: Block
                  leftBracket: {
                  rightBracket: }
              declaredFragment: <testLibraryFragment> null@null
                element: null@null
                  type: Null Function()
              staticType: Null Function()
            separator: :
            value: ConstantPattern
              expression2: IntegerLiteral
                literal: 0
                staticType: int
              matchedValueType: dynamic
        rightBracket: }
        matchedValueType: dynamic
        requiredType: Map<dynamic, dynamic>
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_caseClause_pattern_relational_closure() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(x) => [if (x case == (() {})) 0];
//                      ^^^^^
// [diag.nonConstantRelationalPatternExpression] The relational pattern expression must be a constant.
''');

    var node = result.findNode.ifElement('if (x');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: dynamic
    staticType: dynamic
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: RelationalPattern
        operator: ==
        operand2: ParenthesizedExpression
          leftParenthesis: (
          expression2: FunctionExpression
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
            declaredFragment: <testLibraryFragment> null@null
              element: null@null
                type: Null Function()
            staticType: Null Function()
          rightParenthesis: )
          staticType: Null Function()
        element: dart:core::@class::Object::@method::==
        matchedValueType: dynamic
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_caseClause_pattern_relational_closure_assignsVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(x, Object? v) {
  if (v is int) {
    return [if (x case == (() { v = 0; })) v];
//                         ^^^^^^^^^^^^^
// [diag.nonConstantRelationalPatternExpression] The relational pattern expression must be a constant.
  }
}
''');

    var node = result.findNode.ifElement('if (x');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: dynamic
    staticType: dynamic
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: RelationalPattern
        operator: ==
        operand2: ParenthesizedExpression
          leftParenthesis: (
          expression2: FunctionExpression
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                statements2
                  ExpressionStatement
                    expression2: DirectAssignment
                      target: UnqualifiedNameAssignmentTarget
                        name: v
                        read: <null>
                        write: VariableWriteResolution
                          element: <testLibrary>::@function::f::@formalParameter::v
                          acceptedType: Object?
                      operator: =
                      value: IntegerLiteral
                        literal: 0
                        correspondingParameter: <null>
                        staticType: int
                      staticType: int
                    expression(v1): AssignmentExpression
                      leftHandSide: SimpleIdentifier
                        token: v
                        element: <testLibrary>::@function::f::@formalParameter::v
                        staticType: null
                      operator: =
                      rightHandSide: IntegerLiteral
                        literal: 0
                        correspondingParameter: <null>
                        staticType: int
                      readElement: <null>
                      readType: null
                      writeElement: <testLibrary>::@function::f::@formalParameter::v
                      writeType: Object?
                      element: <null>
                      staticType: int
                    semicolon: ;
                rightBracket: }
            declaredFragment: <testLibraryFragment> null@null
              element: null@null
                type: Null Function()
            staticType: Null Function()
          rightParenthesis: )
          staticType: Null Function()
        element: dart:core::@class::Object::@method::==
        matchedValueType: dynamic
  rightParenthesis: )
  thenElement2: UnqualifiedNameExpression
    name: v
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::v
      type: Object?
    staticType: Object?
  thenElement(v1): SimpleIdentifier
    token: v
    element: <testLibrary>::@function::f::@formalParameter::v
    staticType: Object?
''');
  }

  test_caseClause_topLevelVariableInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final x = 0;
final y = [ if (x case var a) a ];
''');

    var node = result.findNode.singleIfElement;
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      type: int
    staticType: int
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@getter::x
    staticType: int
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@40
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
  rightParenthesis: )
  thenElement2: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: a@40
      type: int
    staticType: int
  thenElement(v1): SimpleIdentifier
    token: a
    element: a@40
    staticType: int
''');
  }

  test_caseClause_variables_scope() async {
    // Each `guardedPattern` introduces a new case scope which is where the
    // variables defined by that case's pattern are bound.
    // There is no initializing expression for the variables in a case pattern,
    // but they are considered initialized after the entire case pattern,
    // before the guard expression if there is one. However, all pattern
    // variables are in scope in the entire pattern.
    var result = await resolveTestCodeWithDiagnostics(r'''
const a = 0;
void f(Object x) {
  [
    if (x case [int a, == a] when a > 0)
//                  ^
// [context 1] The declaration of 'a' is here.
//                        ^
// [diag.nonConstantRelationalPatternExpression] The relational pattern expression must be a constant.
// [diag.referencedBeforeDeclaration][context 1] Local variable 'a' can't be referenced before it is declared.
      a
    else
      a
  ];
}
''');

    var node = result.findNode.ifElement('if');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: Object
    staticType: Object
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ListPattern
        leftBracket: [
        elements
          DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@56
              element: isPublic
                type: int
            matchedValueType: Object?
          RelationalPattern
            operator: ==
            operand2: UnqualifiedNameExpression
              name: a
              resolution: VariableReadResolution
                element: a@56
                type: int
              staticType: int
            operand(v1): SimpleIdentifier
              token: a
              element: a@56
              staticType: int
            element: dart:core::@class::Object::@method::==
            matchedValueType: Object?
        rightBracket: ]
        matchedValueType: Object
        requiredType: List<Object?>
      whenClause: WhenClause
        whenKeyword: when
        expression2: BinaryOperatorInvocation
          leftOperand: UnqualifiedNameExpression
            name: a
            resolution: VariableReadResolution
              element: a@56
              type: int
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          binaryOperator: greaterThan
          element: dart:core::@class::num::@method::>
          staticType: bool
        expression(v1): BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@56
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenElement2: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: a@56
      type: int
    staticType: int
  thenElement(v1): SimpleIdentifier
    token: a
    element: a@56
    staticType: int
  elseKeyword: else
  elseElement2: UnqualifiedNameExpression
    name: a
    resolution: GetterInvocationResolution
      element: <testLibrary>::@getter::a
      type: int
    staticType: int
  elseElement(v1): SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_caseClause_variables_single() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  [
    if (x case int a when a > 0)
      a
    else
      a // error
//    ^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'a'.
  ];
}
''');

    var node = result.findNode.ifElement('if (x');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: Object
    staticType: Object
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@42
          element: isPublic
            type: int
        matchedValueType: Object
      whenClause: WhenClause
        whenKeyword: when
        expression2: BinaryOperatorInvocation
          leftOperand: UnqualifiedNameExpression
            name: a
            resolution: VariableReadResolution
              element: a@42
              type: int
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          binaryOperator: greaterThan
          element: dart:core::@class::num::@method::>
          staticType: bool
        expression(v1): BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@42
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenElement2: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: a@42
      type: int
    staticType: int
  thenElement(v1): SimpleIdentifier
    token: a
    element: a@42
    staticType: int
  elseKeyword: else
  elseElement2: UnqualifiedNameExpression
    name: a
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  elseElement(v1): SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
''');
  }

  test_expression_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    [if (super) 0 else 1];
//       ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singleIfElement;
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: InvalidSuperExpression
    superReference: SuperReference
      superKeyword: super
    staticType: InvalidType
  expression(v1): SuperExpression
    superKeyword: super
    staticType: A
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 0
    staticType: int
  elseKeyword: else
  elseElement2: IntegerLiteral
    literal: 1
    staticType: int
''');
  }

  test_rewrite_caseClause_pattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  [if (x case const A()) 0];
}

class A {
  const A();
}
''');

    var node = result.findNode.ifElement('if');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: Object
    staticType: Object
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        constKeyword: const
        expression2: ConstructorInvocation
          constructorReference: ConstructorReference2
            typeReference: ConstructorTypeReference
              name: A
              element: <testLibrary>::@class::A
              type: A
            element: <testLibrary>::@class::A::@constructor::new
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticType: A
        expression(v1): InstanceCreationExpression
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
        matchedValueType: Object
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_rewrite_expression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool Function() a) {
  [if (a()) 0];
}
''');

    var node = result.findNode.ifElement('if');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: CallInvocation
    receiver: UnqualifiedNameExpression
      name: a
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::a
        type: bool Function()
      staticType: bool Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: FunctionTypeInvocationResolution
      invokeType: bool Function()
      type: bool
    staticType: bool
  expression(v1): FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: bool Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: bool Function()
    staticType: bool
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_rewrite_expression_caseClause() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int Function() a) {
  [if (a() case 0) 1];
}
''');

    var node = result.findNode.ifElement('if');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: CallInvocation
    receiver: UnqualifiedNameExpression
      name: a
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::a
        type: int Function()
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: FunctionTypeInvocationResolution
      invokeType: int Function()
      type: int
    staticType: int
  expression(v1): FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function()
    staticType: int
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression2: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: int
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 1
    staticType: int
''');
  }

  test_rewrite_whenClause() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x, bool Function() a) {
  [if (x case 0 when a()) 1];
}
''');

    var node = result.findNode.ifElement('if');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: Object
    staticType: Object
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression2: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object
      whenClause: WhenClause
        whenKeyword: when
        expression2: CallInvocation
          receiver: UnqualifiedNameExpression
            name: a
            resolution: VariableReadResolution
              element: <testLibrary>::@function::f::@formalParameter::a
              type: bool Function()
            staticType: bool Function()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          resolution: FunctionTypeInvocationResolution
            invokeType: bool Function()
            type: bool
          staticType: bool
        expression(v1): FunctionExpressionInvocation
          function: SimpleIdentifier
            token: a
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: bool Function()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          element: <null>
          staticInvokeType: bool Function()
          staticType: bool
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 1
    staticType: int
''');
  }

  test_whenClause() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  [if (x case 0 when true) 1 else 2];
}
''');

    var node = result.findNode.ifElement('if');
    assertResolvedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: Object
    staticType: Object
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression2: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object
      whenClause: WhenClause
        whenKeyword: when
        expression2: BooleanLiteral
          literal: true
          staticType: bool
  rightParenthesis: )
  thenElement2: IntegerLiteral
    literal: 1
    staticType: int
  elseKeyword: else
  elseElement2: IntegerLiteral
    literal: 2
    staticType: int
''');
  }
}
