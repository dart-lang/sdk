// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StatementMayCompleteNormallyTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class StatementMayCompleteNormallyTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    nodeTextConfiguration.withMayCompleteNormally = true;
  }

  test_assertStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  assert(b);
}
''');

    var node = result.findNode.singleAssertStatement;
    assertResolvedNodeText(node, r'''
AssertStatement
  assertKeyword: assert
  leftParenthesis: (
  condition2: UnqualifiedNameExpression
    name: b
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::b
      type: bool
    staticType: bool
  condition(v1): SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  rightParenthesis: )
  semicolon: ;
  mayCompleteNormally: true
''');
  }

  test_block_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  {}
}
''');

    var node = result.findNode.block('{}');
    assertResolvedNodeText(node, r'''
Block
  leftBracket: {
  rightBracket: }
  mayCompleteNormally: true
''');
  }

  test_block_return() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  {
    return;
  }
}
''');

    var node = result.findNode.block('{\n    return');
    assertResolvedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      semicolon: ;
      mayCompleteNormally: false
  rightBracket: }
  mayCompleteNormally: false
''');
  }

  test_breakStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  while (true) {
    break;
  }
}
''');

    var node = result.findNode.singleWhileStatement;
    assertResolvedNodeText(node, r'''
WhileStatement
  whileKeyword: while
  leftParenthesis: (
  condition2: BooleanLiteral
    literal: true
    staticType: bool
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      BreakStatement
        breakKeyword: break
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  mayCompleteNormally: true
''');
  }

  test_continueStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  while (b) {
    continue;
  }
}
''');

    var node = result.findNode.singleWhileStatement;
    assertResolvedNodeText(node, r'''
WhileStatement
  whileKeyword: while
  leftParenthesis: (
  condition2: UnqualifiedNameExpression
    name: b
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::b
      type: bool
    staticType: bool
  condition(v1): SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ContinueStatement
        continueKeyword: continue
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  mayCompleteNormally: true
''');
  }

  test_doStatement_return() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  do {
    return;
  } while (b);
//^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.singleDoStatement;
    assertResolvedNodeText(node, r'''
DoStatement
  doKeyword: do
  body: Block
    leftBracket: {
    statements
      ReturnStatement
        returnKeyword: return
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  whileKeyword: while
  leftParenthesis: (
  condition2: UnqualifiedNameExpression
    name: b
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::b
      type: bool
    staticType: bool
  condition(v1): SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  rightParenthesis: )
  semicolon: ;
  mayCompleteNormally: false
''');
  }

  test_emptyStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  ;
}
''');

    var node = result.findNode.singleEmptyStatement;
    assertResolvedNodeText(node, r'''
EmptyStatement
  semicolon: ;
  mayCompleteNormally: true
''');
  }

  test_expressionStatement_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  g();
}

void g() {}
''');

    var node = result.findNode.singleExpressionStatement;
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression2: UnqualifiedFunctionInvocation
    name: g
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@function::g
      invokeType: void Function()
      type: void
    staticType: void
  expression(v1): MethodInvocation
    methodName: SimpleIdentifier
      token: g
      element: <testLibrary>::@function::g
      staticType: void Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: void Function()
    staticType: void
  semicolon: ;
  mayCompleteNormally: true
''');
  }

  test_expressionStatement_invocation_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  g();
}

Never g() => throw 0;
''');

    var node = result.findNode.singleExpressionStatement;
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression2: UnqualifiedFunctionInvocation
    name: g
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@function::g
      invokeType: Never Function()
      type: Never
    staticType: Never
  expression(v1): MethodInvocation
    methodName: SimpleIdentifier
      token: g
      element: <testLibrary>::@function::g
      staticType: Never Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: Never Function()
    staticType: Never
  semicolon: ;
  mayCompleteNormally: false
''');
  }

  test_expressionStatement_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x;
}
''');

    var node = result.findNode.singleExpressionStatement;
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression2: UnqualifiedNameExpression
    name: x
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: Never
    staticType: Never
  expression(v1): SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  semicolon: ;
  mayCompleteNormally: false
''');
  }

  test_expressionStatement_stringInterpolation_throw() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  'a${throw 0}b';
//            ^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.singleExpressionStatement;
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression2: StringInterpolation
    elements
      InterpolationString
        contents: 'a
      InterpolationExpression
        leftBracket: ${
        expression2: ThrowExpression
          throwKeyword: throw
          expression2: IntegerLiteral
            literal: 0
            staticType: int
          staticType: Never
        rightBracket: }
      InterpolationString
        contents: b'
    staticType: String
    stringValue: null
  semicolon: ;
  mayCompleteNormally: false
''');
  }

  test_expressionStatement_throw() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  throw 0;
}
''');

    var node = result.findNode.singleExpressionStatement;
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression2: ThrowExpression
    throwKeyword: throw
    expression2: IntegerLiteral
      literal: 0
      staticType: int
    staticType: Never
  semicolon: ;
  mayCompleteNormally: false
''');
  }

  test_forStatement_forEach() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> values) {
  for (var _ in values) {}
}
''');

    var node = result.findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: _
      declaredFragment: isPrivate _@38
        element: hasImplicitType isPrivate
          type: int
    inKeyword: in
    iterable2: UnqualifiedNameExpression
      name: values
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::values
        type: List<int>
      staticType: List<int>
    iterable(v1): SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
    mayCompleteNormally: true
  mayCompleteNormally: true
''');
  }

  test_forStatement_infinite() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (;;) {}
}
''');

    var node = result.findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    leftSeparator: ;
    rightSeparator: ;
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
    mayCompleteNormally: true
  mayCompleteNormally: false
''');
  }

  test_functionDeclarationStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g() {
//     ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
    return;
  }
}
''');

    var node = result.findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          statements
            ReturnStatement
              returnKeyword: return
              semicolon: ;
              mayCompleteNormally: false
          rightBracket: }
          mayCompleteNormally: false
      declaredFragment: <testLibraryFragment> g@18
        element: g@18
          type: void Function()
      staticType: void Function()
    declaredFragment: <testLibraryFragment> g@18
      element: g@18
        type: void Function()
  mayCompleteNormally: true
''');
  }

  test_ifStatement_noElse() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  if (b) {
    return;
  }
}
''');

    var node = result.findNode.singleIfStatement;
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: b
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::b
      type: bool
    staticType: bool
  expression(v1): SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ReturnStatement
        returnKeyword: return
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  mayCompleteNormally: true
''');
  }

  test_ifStatement_thenElse_return() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  if (b) {
    return;
  } else {
    return;
  }
}
''');

    var node = result.findNode.singleIfStatement;
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: b
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::b
      type: bool
    staticType: bool
  expression(v1): SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ReturnStatement
        returnKeyword: return
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  elseKeyword: else
  elseStatement: Block
    leftBracket: {
    statements
      ReturnStatement
        returnKeyword: return
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  mayCompleteNormally: false
''');
  }

  test_labeledStatement_break() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  label: {
    break label;
  }
}
''');

    var node = result.findNode.singleLabeledStatement;
    assertResolvedNodeText(node, r'''
LabeledStatement
  labels
    Label
      name: label
      colon: :
      declaredFragment: <testLibraryFragment> label@13
  statement: Block
    leftBracket: {
    statements
      BreakStatement
        breakKeyword: break
        label: LabelReference
          name: label
          element: label@13
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  mayCompleteNormally: true
''');
  }

  test_patternVariableDeclarationStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, int) pair) {
  var (_, _) = pair;
}
''');

    var node = result.findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: WildcardPattern
            name: _
            matchedValueType: int
          element: <null>
        PatternField
          pattern: WildcardPattern
            name: _
            matchedValueType: int
          element: <null>
      rightParenthesis: )
      matchedValueType: (int, int)
    equals: =
    expression2: UnqualifiedNameExpression
      name: pair
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::pair
        type: (int, int)
      staticType: (int, int)
    expression(v1): SimpleIdentifier
      token: pair
      element: <testLibrary>::@function::f::@formalParameter::pair
      staticType: (int, int)
    patternTypeSchema: (_, _)
  semicolon: ;
  mayCompleteNormally: true
''');
  }

  test_returnStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f() {
  return 0;
}
''');

    var node = result.findNode.singleReturnStatement;
    assertResolvedNodeText(node, r'''
ReturnStatement
  returnKeyword: return
  expression2: IntegerLiteral
    literal: 0
    staticType: int
  semicolon: ;
  mayCompleteNormally: false
''');
  }

  test_switchStatement_exhaustive_return() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { first, second }

int f(E e) {
  switch (e) {
    case E.first:
      return 0;
    case E.second:
      return 1;
  }
}
''');

    var node = result.findNode.singleSwitchStatement;
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: e
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::e
      type: E
    staticType: E
  expression(v1): SimpleIdentifier
    token: e
    element: <testLibrary>::@function::f::@formalParameter::e
    staticType: E
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression2: ReceiverPropertyExtraction
            receiver: StaticQualifier
              name: E
              element: <testLibrary>::@enum::E
            operator: .
            name: first
            resolution: GetterInvocationResolution
              element: <testLibrary>::@enum::E::@getter::first
              invokeType: E Function()
              type: E
            staticType: E
          expression(v1): PrefixedIdentifier
            prefix: SimpleIdentifier
              token: E
              element: <testLibrary>::@enum::E
              staticType: null
            period: .
            identifier: SimpleIdentifier
              token: first
              element: <testLibrary>::@enum::E::@getter::first
              staticType: E
            element: <testLibrary>::@enum::E::@getter::first
            staticType: E
          matchedValueType: E
      colon: :
      statements
        ReturnStatement
          returnKeyword: return
          expression2: IntegerLiteral
            literal: 0
            staticType: int
          semicolon: ;
          mayCompleteNormally: false
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression2: ReceiverPropertyExtraction
            receiver: StaticQualifier
              name: E
              element: <testLibrary>::@enum::E
            operator: .
            name: second
            resolution: GetterInvocationResolution
              element: <testLibrary>::@enum::E::@getter::second
              invokeType: E Function()
              type: E
            staticType: E
          expression(v1): PrefixedIdentifier
            prefix: SimpleIdentifier
              token: E
              element: <testLibrary>::@enum::E
              staticType: null
            period: .
            identifier: SimpleIdentifier
              token: second
              element: <testLibrary>::@enum::E::@getter::second
              staticType: E
            element: <testLibrary>::@enum::E::@getter::second
            staticType: E
          matchedValueType: E
      colon: :
      statements
        ReturnStatement
          returnKeyword: return
          expression2: IntegerLiteral
            literal: 1
            staticType: int
          semicolon: ;
          mayCompleteNormally: false
  rightBracket: }
  mayCompleteNormally: false
''');
  }

  test_switchStatement_notExhaustive() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int i) {
  switch (i) {
    case 0:
      return;
  }
}
''');

    var node = result.findNode.singleSwitchStatement;
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression2: UnqualifiedNameExpression
    name: i
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::i
      type: int
    staticType: int
  expression(v1): SimpleIdentifier
    token: i
    element: <testLibrary>::@function::f::@formalParameter::i
    staticType: int
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression2: IntegerLiteral
            literal: 0
            staticType: int
          matchedValueType: int
      colon: :
      statements
        ReturnStatement
          returnKeyword: return
          semicolon: ;
          mayCompleteNormally: false
  rightBracket: }
  mayCompleteNormally: true
''');
  }

  test_tryStatement_catch() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {
    return;
  } catch (_) {}
}
''');

    var node = result.findNode.singleTryStatement;
    assertResolvedNodeText(node, r'''
TryStatement
  tryKeyword: try
  body: Block
    leftBracket: {
    statements
      ReturnStatement
        returnKeyword: return
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  catchClauses
    CatchClause
      catchKeyword: catch
      leftParenthesis: (
      exceptionParameter: CatchClauseParameter
        name: _
        declaredFragment: isFinal isPrivate _@42
          element: hasImplicitType isFinal isPrivate
            type: Object
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
        mayCompleteNormally: true
  mayCompleteNormally: true
''');
  }

  test_tryStatement_finally_return() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} finally {
    return;
  }
}
''');

    var node = result.findNode.singleTryStatement;
    assertResolvedNodeText(node, r'''
TryStatement
  tryKeyword: try
  body: Block
    leftBracket: {
    rightBracket: }
    mayCompleteNormally: true
  finallyKeyword: finally
  finallyBlock: Block
    leftBracket: {
    statements
      ReturnStatement
        returnKeyword: return
        semicolon: ;
        mayCompleteNormally: false
    rightBracket: }
    mayCompleteNormally: false
  mayCompleteNormally: false
''');
  }

  test_unreachable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  return;
  0;
//^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.singleExpressionStatement;
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression2: IntegerLiteral
    literal: 0
    staticType: int
  semicolon: ;
  mayCompleteNormally: false
''');
  }

  test_variableDeclarationStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var _ = 0;
}
''');

    var node = result.findNode.singleVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: _
        equals: =
        initializer2: IntegerLiteral
          literal: 0
          staticType: int
        declaredFragment: isPrivate _@17
          element: hasImplicitType isPrivate
            type: int
  semicolon: ;
  mayCompleteNormally: true
''');
  }

  test_variableDeclarationStatement_throw() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int _ = throw 0;
}
''');

    var node = result.findNode.singleVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    variables
      VariableDeclaration
        name: _
        equals: =
        initializer2: ThrowExpression
          throwKeyword: throw
          expression2: IntegerLiteral
            literal: 0
            staticType: int
          staticType: Never
        declaredFragment: isPrivate _@17
          element: isPrivate
            type: int
  semicolon: ;
  mayCompleteNormally: false
''');
  }

  test_whileStatement_true() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  while (true) {}
}
''');

    var node = result.findNode.singleWhileStatement;
    assertResolvedNodeText(node, r'''
WhileStatement
  whileKeyword: while
  leftParenthesis: (
  condition2: BooleanLiteral
    literal: true
    staticType: bool
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
    mayCompleteNormally: true
  mayCompleteNormally: false
''');
  }

  test_yieldStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Iterable<int> f() sync* {
  yield 0;
}
''');

    var node = result.findNode.singleYieldStatement;
    assertResolvedNodeText(node, r'''
YieldStatement
  yieldKeyword: yield
  expression2: IntegerLiteral
    literal: 0
    staticType: int
  semicolon: ;
  mayCompleteNormally: true
''');
  }
}
