// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NNBDParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NNBDParserTest extends ParserDiagnosticsTest {
  void test_assignment_complex() {
    var parseResult = parseStringWithErrors(r'''
D? foo(X? x) {
  X? x1;
  X? x2 = x + bar(7);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: X
          question: ?
        variables
          VariableDeclaration
            name: x1
      semicolon: ;
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: X
          question: ?
        variables
          VariableDeclaration
            name: x2
            equals: =
            initializer: BinaryExpression
              leftOperand: SimpleIdentifier
                token: x
              operator: +
              rightOperand: MethodInvocation
                methodName: SimpleIdentifier
                  token: bar
                argumentList: ArgumentList
                  leftParenthesis: (
                  arguments
                    IntegerLiteral
                      literal: 7
                  rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_assignment_complex2() {
    var parseResult = parseStringWithErrors('''
void f() {
  A? a;
  String? s = '';
  a
    ?..foo().length
    ..x27 = s!
    ..toString().length;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: A
          question: ?
        variables
          VariableDeclaration
            name: a
      semicolon: ;
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: String
          question: ?
        variables
          VariableDeclaration
            name: s
            equals: =
            initializer: SimpleStringLiteral
              literal: ''
      semicolon: ;
    ExpressionStatement
      expression: CascadeExpression
        target: SimpleIdentifier
          token: a
        cascadeSections
          PropertyAccess
            target: MethodInvocation
              operator: ?..
              methodName: SimpleIdentifier
                token: foo
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
            operator: .
            propertyName: SimpleIdentifier
              token: length
          AssignmentExpression
            leftHandSide: PropertyAccess
              operator: ..
              propertyName: SimpleIdentifier
                token: x27
            operator: =
            rightHandSide: PostfixExpression
              operand: SimpleIdentifier
                token: s
              operator: !
          PropertyAccess
            target: MethodInvocation
              operator: ..
              methodName: SimpleIdentifier
                token: toString
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
            operator: .
            propertyName: SimpleIdentifier
              token: length
      semicolon: ;
  rightBracket: }
''');
  }

  void test_assignment_simple() {
    var parseResult = parseStringWithErrors(r'''
D? foo(X? x) {
  X? x1;
  X? x2 = x;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: X
          question: ?
        variables
          VariableDeclaration
            name: x1
      semicolon: ;
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: X
          question: ?
        variables
          VariableDeclaration
            name: x2
            equals: =
            initializer: SimpleIdentifier
              token: x
      semicolon: ;
  rightBracket: }
''');
  }

  void test_bangBeforeFunctionCall1() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  Function? f1;
  f1!(42);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: Function
          question: ?
        variables
          VariableDeclaration
            name: f1
      semicolon: ;
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: PostfixExpression
          operand: SimpleIdentifier
            token: f1
          operator: !
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 42
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_bangBeforeFunctionCall2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  Function f2;
  f2!<int>(42);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: Function
        variables
          VariableDeclaration
            name: f2
      semicolon: ;
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: PostfixExpression
          operand: SimpleIdentifier
            token: f2
          operator: !
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 42
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_bangQuestionIndex() {
    var parseResult = parseStringWithErrors(r'''
void f(dynamic a) {
  a!?[0];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: PostfixExpression
          operand: SimpleIdentifier
            token: a
          operator: !
        question: ?
        leftBracket: [
        index: IntegerLiteral
          literal: 0
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_binary_expression_statement() {
    var parseResult = parseStringWithErrors(r'''
D? foo(X? x) {
  X ?? x2;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: BinaryExpression
        leftOperand: SimpleIdentifier
          token: X
        operator: ??
        rightOperand: SimpleIdentifier
          token: x2
      semicolon: ;
  rightBracket: }
''');
  }

  void test_cascade_withNullCheck_indexExpression() {
    var parseResult = parseStringWithErrors('''
void f() {
  a?..[27];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: CascadeExpression
        target: SimpleIdentifier
          token: a
        cascadeSections
          IndexExpression
            period: ?..
            leftBracket: [
            index: IntegerLiteral
              literal: 27
            rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_cascade_withNullCheck_invalid() {
    var parseResult = parseStringWithErrors('''
void f() { a..[27]?..x; }
''');
    parseResult.assertErrors([error(diag.nullAwareCascadeOutOfOrder, 18, 3)]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: CascadeExpression
        target: SimpleIdentifier
          token: a
        cascadeSections
          IndexExpression
            period: ..
            leftBracket: [
            index: IntegerLiteral
              literal: 27
            rightBracket: ]
          PropertyAccess
            operator: ?..
            propertyName: SimpleIdentifier
              token: x
      semicolon: ;
  rightBracket: }
''');
  }

  void test_cascade_withNullCheck_methodInvocation() {
    var parseResult = parseStringWithErrors('''
void f() {
  a?..foo();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: CascadeExpression
        target: SimpleIdentifier
          token: a
        cascadeSections
          MethodInvocation
            operator: ?..
            methodName: SimpleIdentifier
              token: foo
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_cascade_withNullCheck_propertyAccess() {
    var parseResult = parseStringWithErrors('''
void f() {
  a?..x27;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: CascadeExpression
        target: SimpleIdentifier
          token: a
        cascadeSections
          PropertyAccess
            operator: ?..
            propertyName: SimpleIdentifier
              token: x27
      semicolon: ;
  rightBracket: }
''');
  }

  void test_conditional() {
    var parseResult = parseStringWithErrors(r'''
D? foo(X? x) {
  X ? 7 : y;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: ConditionalExpression
        condition: SimpleIdentifier
          token: X
        question: ?
        thenExpression: IntegerLiteral
          literal: 7
        colon: :
        elseExpression: SimpleIdentifier
          token: y
      semicolon: ;
  rightBracket: }
''');
  }

  void test_conditional_complex() {
    var parseResult = parseStringWithErrors(r'''
D? foo(X? x) {
  X ? x2 = x + bar(7) : y;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: ConditionalExpression
        condition: SimpleIdentifier
          token: X
        question: ?
        thenExpression: AssignmentExpression
          leftHandSide: SimpleIdentifier
            token: x2
          operator: =
          rightHandSide: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: +
            rightOperand: MethodInvocation
              methodName: SimpleIdentifier
                token: bar
              argumentList: ArgumentList
                leftParenthesis: (
                arguments
                  IntegerLiteral
                    literal: 7
                rightParenthesis: )
        colon: :
        elseExpression: SimpleIdentifier
          token: y
      semicolon: ;
  rightBracket: }
''');
  }

  void test_conditional_error() {
    var parseResult = parseStringWithErrors(r'''
D? foo(X? x) { X ? ? x2 = x + bar(7) : y; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 1),
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 40, 1),
    ]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: ConditionalExpression
        condition: SimpleIdentifier
          token: X
        question: ?
        thenExpression: ConditionalExpression
          condition: SimpleIdentifier
            token: <empty> <synthetic>
          question: ?
          thenExpression: AssignmentExpression
            leftHandSide: SimpleIdentifier
              token: x2
            operator: =
            rightHandSide: BinaryExpression
              leftOperand: SimpleIdentifier
                token: x
              operator: +
              rightOperand: MethodInvocation
                methodName: SimpleIdentifier
                  token: bar
                argumentList: ArgumentList
                  leftParenthesis: (
                  arguments
                    IntegerLiteral
                      literal: 7
                  rightParenthesis: )
          colon: :
          elseExpression: SimpleIdentifier
            token: y
        colon: : <synthetic>
        elseExpression: SimpleIdentifier
          token: <empty> <synthetic>
      semicolon: ;
  rightBracket: }
''');
  }

  void test_conditional_simple() {
    var parseResult = parseStringWithErrors(r'''
D? foo(X? x) {
  X ? x2 = x : y;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: ConditionalExpression
        condition: SimpleIdentifier
          token: X
        question: ?
        thenExpression: AssignmentExpression
          leftHandSide: SimpleIdentifier
            token: x2
          operator: =
          rightHandSide: SimpleIdentifier
            token: x
        colon: :
        elseExpression: SimpleIdentifier
          token: y
      semicolon: ;
  rightBracket: }
''');
  }

  void test_for() {
    var parseResult = parseStringWithErrors('''
void f() {
  for (int x = 0; x < 7; ++x) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ForStatement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForPartsWithDeclarations
        variables: VariableDeclarationList
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: x
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: x
          operator: <
          rightOperand: IntegerLiteral
            literal: 7
        rightSeparator: ;
        updaters
          PrefixExpression
            operator: ++
            operand: SimpleIdentifier
              token: x
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_for_conditional() {
    var parseResult = parseStringWithErrors('''
void f() {
  for (x ? y = 7 : y = 8; y < 10; ++y) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ForStatement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForPartsWithExpression
        initialization: ConditionalExpression
          condition: SimpleIdentifier
            token: x
          question: ?
          thenExpression: AssignmentExpression
            leftHandSide: SimpleIdentifier
              token: y
            operator: =
            rightHandSide: IntegerLiteral
              literal: 7
          colon: :
          elseExpression: AssignmentExpression
            leftHandSide: SimpleIdentifier
              token: y
            operator: =
            rightHandSide: IntegerLiteral
              literal: 8
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: y
          operator: <
          rightOperand: IntegerLiteral
            literal: 10
        rightSeparator: ;
        updaters
          PrefixExpression
            operator: ++
            operand: SimpleIdentifier
              token: y
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_for_nullable() {
    var parseResult = parseStringWithErrors('''
void f() {
  for (int? x = 0; x < 7; ++x) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ForStatement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForPartsWithDeclarations
        variables: VariableDeclarationList
          type: NamedType
            name: int
            question: ?
          variables
            VariableDeclaration
              name: x
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: x
          operator: <
          rightOperand: IntegerLiteral
            literal: 7
        rightSeparator: ;
        updaters
          PrefixExpression
            operator: ++
            operand: SimpleIdentifier
              token: x
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_foreach() {
    var parseResult = parseStringWithErrors('''
void f() {
  for (int x in [7]) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ForStatement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithDeclaration
        loopVariable: DeclaredIdentifier
          type: NamedType
            name: int
          name: x
        inKeyword: in
        iterable: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 7
          rightBracket: ]
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_foreach_nullable() {
    var parseResult = parseStringWithErrors('''
void f() {
  for (int? x in [7, null]) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ForStatement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithDeclaration
        loopVariable: DeclaredIdentifier
          type: NamedType
            name: int
            question: ?
          name: x
        inKeyword: in
        iterable: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 7
            NullLiteral
              literal: null
          rightBracket: ]
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  test_fuzz_38113() {
    var parseResult = parseStringWithErrors(r'''
+t{{r?this}}
''');
    parseResult.assertErrors([
      error(diag.expectedExecutable, 0, 1),
      error(diag.missingFunctionParameters, 1, 1),
      error(diag.expectedToken, 6, 4),
      error(diag.expectedToken, 10, 1),
      error(diag.missingIdentifier, 10, 1),
    ]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: ConditionalExpression
            condition: SimpleIdentifier
              token: r
            question: ?
            thenExpression: ThisExpression
              thisKeyword: this
            colon: : <synthetic>
            elseExpression: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
      rightBracket: }
  rightBracket: }
''');
  }

  void test_gft_nullable() {
    var parseResult = parseStringWithErrors('''
void f() {
  C? Function() x = 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: GenericFunctionType
          returnType: NamedType
            name: C
            question: ?
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_gft_nullable_1() {
    var parseResult = parseStringWithErrors('''
void f() {
  C Function()? x = 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: GenericFunctionType
          returnType: NamedType
            name: C
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          question: ?
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_gft_nullable_2() {
    var parseResult = parseStringWithErrors('''
void f() {
  C? Function()? x = 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: GenericFunctionType
          returnType: NamedType
            name: C
            question: ?
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          question: ?
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_gft_nullable_3() {
    var parseResult = parseStringWithErrors('''
void f() {
  C? Function()? Function()? x = 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: GenericFunctionType
          returnType: GenericFunctionType
            returnType: NamedType
              name: C
              question: ?
            functionKeyword: Function
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            question: ?
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          question: ?
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_gft_nullable_prefixed() {
    var parseResult = parseStringWithErrors('''
void f() {
  C.a? Function()? x = 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: GenericFunctionType
          returnType: NamedType
            importPrefix: ImportPrefixReference
              name: C
              period: .
            name: a
            question: ?
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          question: ?
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_indexed() {
    var parseResult = parseStringWithErrors('''
void f() {
  a[7];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: SimpleIdentifier
          token: a
        leftBracket: [
        index: IntegerLiteral
          literal: 7
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_indexed_nullAware() {
    var parseResult = parseStringWithErrors('''
void f() {
  a?[7];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: SimpleIdentifier
          token: a
        question: ?
        leftBracket: [
        index: IntegerLiteral
          literal: 7
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_is_nullable() {
    var parseResult = parseStringWithErrors('''
void f() {
  x is String? ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: ConditionalExpression
        condition: IsExpression
          expression: SimpleIdentifier
            token: x
          isOperator: is
          type: NamedType
            name: String
            question: ?
        question: ?
        thenExpression: ParenthesizedExpression
          leftParenthesis: (
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: +
            rightOperand: SimpleIdentifier
              token: y
          rightParenthesis: )
        colon: :
        elseExpression: SimpleIdentifier
          token: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_is_nullable_parenthesis() {
    var parseResult = parseStringWithErrors('''
void f() {
  (x is String?) ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: ConditionalExpression
        condition: ParenthesizedExpression
          leftParenthesis: (
          expression: IsExpression
            expression: SimpleIdentifier
              token: x
            isOperator: is
            type: NamedType
              name: String
              question: ?
          rightParenthesis: )
        question: ?
        thenExpression: ParenthesizedExpression
          leftParenthesis: (
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: +
            rightOperand: SimpleIdentifier
              token: y
          rightParenthesis: )
        colon: :
        elseExpression: SimpleIdentifier
          token: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_late_as_identifier() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int late;
}

void f(C c) {
  print(c.late);
}

main() {
  f(new C());
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: print
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: c
              period: .
              identifier: SimpleIdentifier
                token: late
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_late_as_identifier_optOut() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 2.2
class C {
  int late;
}

void f(C c) {
  print(c.late);
}

main() {
  f(new C());
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: print
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: c
              period: .
              identifier: SimpleIdentifier
                token: late
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullableTypeInInitializerList_01() {
    var parseResult = parseStringWithErrors(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : x = o as String?, y = 0;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Foo
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              type: NamedType
                name: String
                question: ?
              variables
                VariableDeclaration
                  name: x
            semicolon: ;
          FieldDeclaration
            fields: VariableDeclarationList
              type: NamedType
                name: int
              variables
                VariableDeclaration
                  name: y
            semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: Foo
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: Object
                  question: ?
                name: o
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: x
                equals: =
                expression: AsExpression
                  expression: SimpleIdentifier
                    token: o
                  asOperator: as
                  type: NamedType
                    name: String
                    question: ?
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: y
                equals: =
                expression: IntegerLiteral
                  literal: 0
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_nullableTypeInInitializerList_02() {
    var parseResult = parseStringWithErrors(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : y = o is String? ? o.length : null, x = null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Foo
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              type: NamedType
                name: String
                question: ?
              variables
                VariableDeclaration
                  name: x
            semicolon: ;
          FieldDeclaration
            fields: VariableDeclarationList
              type: NamedType
                name: int
              variables
                VariableDeclaration
                  name: y
            semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: Foo
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: Object
                  question: ?
                name: o
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: y
                equals: =
                expression: ConditionalExpression
                  condition: IsExpression
                    expression: SimpleIdentifier
                      token: o
                    isOperator: is
                    type: NamedType
                      name: String
                      question: ?
                  question: ?
                  thenExpression: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: o
                    period: .
                    identifier: SimpleIdentifier
                      token: length
                  colon: :
                  elseExpression: NullLiteral
                    literal: null
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: x
                equals: =
                expression: NullLiteral
                  literal: null
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_nullableTypeInInitializerList_03() {
    var parseResult = parseStringWithErrors(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : y = o is String ? o.length : null, x = null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Foo
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              type: NamedType
                name: String
                question: ?
              variables
                VariableDeclaration
                  name: x
            semicolon: ;
          FieldDeclaration
            fields: VariableDeclarationList
              type: NamedType
                name: int
              variables
                VariableDeclaration
                  name: y
            semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: Foo
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: Object
                  question: ?
                name: o
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: y
                equals: =
                expression: ConditionalExpression
                  condition: IsExpression
                    expression: SimpleIdentifier
                      token: o
                    isOperator: is
                    type: NamedType
                      name: String
                  question: ?
                  thenExpression: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: o
                    period: .
                    identifier: SimpleIdentifier
                      token: length
                  colon: :
                  elseExpression: NullLiteral
                    literal: null
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: x
                equals: =
                expression: NullLiteral
                  literal: null
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_nullCheck() {
    var parseResult = parseStringWithErrors(r'''
void f(int? y) {
  var x = y!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: SimpleIdentifier
                token: y
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckAfterGetterAccess() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g.x!.y + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PropertyAccess
                target: PostfixExpression
                  operand: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: g
                    period: .
                    identifier: SimpleIdentifier
                      token: x
                  operator: !
                operator: .
                propertyName: SimpleIdentifier
                  token: y
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckAfterMethodCall() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g.m()!.y + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PropertyAccess
                target: PostfixExpression
                  operand: MethodInvocation
                    target: SimpleIdentifier
                      token: g
                    operator: .
                    methodName: SimpleIdentifier
                      token: m
                    argumentList: ArgumentList
                      leftParenthesis: (
                      rightParenthesis: )
                  operator: !
                operator: .
                propertyName: SimpleIdentifier
                  token: y
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckBeforeGetterAccess() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g!.x + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PropertyAccess
                target: PostfixExpression
                  operand: SimpleIdentifier
                    token: g
                  operator: !
                operator: .
                propertyName: SimpleIdentifier
                  token: x
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckBeforeIndex() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  foo.bar!.baz[arg];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: PropertyAccess
          target: PostfixExpression
            operand: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: foo
              period: .
              identifier: SimpleIdentifier
                token: bar
            operator: !
          operator: .
          propertyName: SimpleIdentifier
            token: baz
        leftBracket: [
        index: SimpleIdentifier
          token: arg
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckBeforeMethodCall() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g!.m() + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: MethodInvocation
                target: PostfixExpression
                  operand: SimpleIdentifier
                    token: g
                  operator: !
                operator: .
                methodName: SimpleIdentifier
                  token: m
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckFunctionResult() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g()! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: MethodInvocation
                  methodName: SimpleIdentifier
                    token: g
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckIndexedValue() {
    var parseResult = parseStringWithErrors(r'''
void f(int? y) {
  var x = y[0]! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: IndexExpression
                  target: SimpleIdentifier
                    token: y
                  leftBracket: [
                  index: IntegerLiteral
                    literal: 0
                  rightBracket: ]
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckIndexedValue2() {
    var parseResult = parseStringWithErrors(r'''
void f(int? y) {
  var x = super.y[0]! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: IndexExpression
                  target: PropertyAccess
                    target: SuperExpression
                      superKeyword: super
                    operator: .
                    propertyName: SimpleIdentifier
                      token: y
                  leftBracket: [
                  index: IntegerLiteral
                    literal: 0
                  rightBracket: ]
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckInExpression() {
    var parseResult = parseStringWithErrors(r'''
void f(int? y) {
  var x = y! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: SimpleIdentifier
                  token: y
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckMethodResult() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g.m()! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: MethodInvocation
                  target: SimpleIdentifier
                    token: g
                  operator: .
                  methodName: SimpleIdentifier
                    token: m
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckMethodResult2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g?.m()! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: MethodInvocation
                  target: SimpleIdentifier
                    token: g
                  operator: ?.
                  methodName: SimpleIdentifier
                    token: m
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckMethodResult3() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = super.m()! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: MethodInvocation
                  target: SuperExpression
                    superKeyword: super
                  operator: .
                  methodName: SimpleIdentifier
                    token: m
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnConstConstructor() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = const Foo()!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: InstanceCreationExpression
                keyword: const
                constructorName: ConstructorName
                  type: NamedType
                    name: Foo
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnConstructor() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = new Foo()!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: InstanceCreationExpression
                keyword: new
                constructorName: ConstructorName
                  type: NamedType
                    name: Foo
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  obj![arg];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: PostfixExpression
          operand: SimpleIdentifier
            token: obj
          operator: !
        leftBracket: [
        index: SimpleIdentifier
          token: arg
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  obj![arg]![arg2];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: PostfixExpression
          operand: IndexExpression
            target: PostfixExpression
              operand: SimpleIdentifier
                token: obj
              operator: !
            leftBracket: [
            index: SimpleIdentifier
              token: arg
            rightBracket: ]
          operator: !
        leftBracket: [
        index: SimpleIdentifier
          token: arg2
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex3() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  foo.bar![arg];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: PostfixExpression
          operand: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: foo
            period: .
            identifier: SimpleIdentifier
              token: bar
          operator: !
        leftBracket: [
        index: SimpleIdentifier
          token: arg
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex4() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  foo!.bar![arg];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: PostfixExpression
          operand: PropertyAccess
            target: PostfixExpression
              operand: SimpleIdentifier
                token: foo
              operator: !
            operator: .
            propertyName: SimpleIdentifier
              token: bar
          operator: !
        leftBracket: [
        index: SimpleIdentifier
          token: arg
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex5() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  foo.bar![arg]![arg2];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: PostfixExpression
          operand: IndexExpression
            target: PostfixExpression
              operand: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo
                period: .
                identifier: SimpleIdentifier
                  token: bar
              operator: !
            leftBracket: [
            index: SimpleIdentifier
              token: arg
            rightBracket: ]
          operator: !
        leftBracket: [
        index: SimpleIdentifier
          token: arg2
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex6() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  foo!.bar![arg]![arg2];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: IndexExpression
        target: PostfixExpression
          operand: IndexExpression
            target: PostfixExpression
              operand: PropertyAccess
                target: PostfixExpression
                  operand: SimpleIdentifier
                    token: foo
                  operator: !
                operator: .
                propertyName: SimpleIdentifier
                  token: bar
              operator: !
            leftBracket: [
            index: SimpleIdentifier
              token: arg
            rightBracket: ]
          operator: !
        leftBracket: [
        index: SimpleIdentifier
          token: arg2
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralDouble() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = 1.2!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: DoubleLiteral
                literal: 1.2
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralInt() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = 0!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: IntegerLiteral
                literal: 0
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralList() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = [1, 2]!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: ListLiteral
                leftBracket: [
                elements
                  IntegerLiteral
                    literal: 1
                  IntegerLiteral
                    literal: 2
                rightBracket: ]
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralMap() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = {1: 2}!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: SetOrMapLiteral
                leftBracket: {
                elements
                  MapLiteralEntry
                    key: IntegerLiteral
                      literal: 1
                    separator: :
                    value: IntegerLiteral
                      literal: 2
                rightBracket: }
                isMap: false
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralSet() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = {1, 2}!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: SetOrMapLiteral
                leftBracket: {
                elements
                  IntegerLiteral
                    literal: 1
                  IntegerLiteral
                    literal: 2
                rightBracket: }
                isMap: false
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralString() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = "seven"!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: SimpleStringLiteral
                literal: "seven"
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnNull() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = null!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: NullLiteral
                literal: null
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnSend() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  obj!(arg);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: PostfixExpression
          operand: SimpleIdentifier
            token: obj
          operator: !
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: arg
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnSend2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  obj!(arg)!(arg2);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: FunctionExpressionInvocation
        function: PostfixExpression
          operand: FunctionExpressionInvocation
            function: PostfixExpression
              operand: SimpleIdentifier
                token: obj
              operator: !
            argumentList: ArgumentList
              leftParenthesis: (
              arguments
                SimpleIdentifier
                  token: arg
              rightParenthesis: )
          operator: !
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: arg2
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnSymbol() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = #seven!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: PostfixExpression
              operand: SymbolLiteral
                poundSign: #
                components
                  seven
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnValue() {
    var parseResult = parseStringWithErrors(r'''
void f(Point p) {
  var x = p.y! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: p
                  period: .
                  identifier: SimpleIdentifier
                    token: y
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckParenthesizedExpression() {
    var parseResult = parseStringWithErrors(r'''
void f(int? y) {
  var x = (y)! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: ParenthesizedExpression
                  leftParenthesis: (
                  expression: SimpleIdentifier
                    token: y
                  rightParenthesis: )
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckPropertyAccess() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g.p! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: g
                  period: .
                  identifier: SimpleIdentifier
                    token: p
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckPropertyAccess2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = g?.p! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: PropertyAccess
                  target: SimpleIdentifier
                    token: g
                  operator: ?.
                  propertyName: SimpleIdentifier
                    token: p
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckPropertyAccess3() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x = super.p! + 7;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: BinaryExpression
              leftOperand: PostfixExpression
                operand: PropertyAccess
                  target: SuperExpression
                    superKeyword: super
                  operator: .
                  propertyName: SimpleIdentifier
                    token: p
                operator: !
              operator: +
              rightOperand: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_postfix_null_assertion_and_unary_prefix_operator_precedence() {
    var parseResult = parseStringWithErrors('''
void f() {
  -x!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: PrefixExpression
        operator: -
        operand: PostfixExpression
          operand: SimpleIdentifier
            token: x
          operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_postfix_null_assertion_of_postfix_expression() {
    var parseResult = parseStringWithErrors('''
void f() {
  x++!;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: PostfixExpression
        operand: PostfixExpression
          operand: SimpleIdentifier
            token: x
          operator: ++
        operator: !
      semicolon: ;
  rightBracket: }
''');
  }
}
