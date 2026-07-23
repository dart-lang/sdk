// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
D? foo(X? x) {
  X? x1;
  X? x2 = x + bar(7);
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: SimpleIdentifier
                token: x
              operator: +
              rightOperand2: MethodInvocation
                methodName: SimpleIdentifier
                  token: bar
                argumentList: ArgumentList
                  leftParenthesis: (
                  arguments2
                    IntegerLiteral
                      literal: 7
                  rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_assignment_complex2() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  A? a;
  String? s = '';
  a
    ?..foo().length
    ..x27 = s!
    ..toString().length;
}
''');
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
            initializer2: SimpleStringLiteral
              literal: ''
      semicolon: ;
    ExpressionStatement
      expression2: CascadeExpression
        target2: SimpleIdentifier
          token: a
        cascadeSections2
          PropertyAccess
            target2: MethodInvocation
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
            leftHandSide2: PropertyAccess
              operator: ..
              propertyName: SimpleIdentifier
                token: x27
            operator: =
            rightHandSide2: PostfixExpression
              operand2: SimpleIdentifier
                token: s
              operator: !
          PropertyAccess
            target2: MethodInvocation
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
D? foo(X? x) {
  X? x1;
  X? x2 = x;
}
''');
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
            initializer2: SimpleIdentifier
              token: x
      semicolon: ;
  rightBracket: }
''');
  }

  void test_bangBeforeFunctionCall1() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  Function? f1;
  f1!(42);
}
''');
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
      expression2: FunctionExpressionInvocation
        function2: PostfixExpression
          operand2: SimpleIdentifier
            token: f1
          operator: !
        argumentList: ArgumentList
          leftParenthesis: (
          arguments2
            IntegerLiteral
              literal: 42
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_bangBeforeFunctionCall2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  Function f2;
  f2!<int>(42);
}
''');
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
      expression2: FunctionExpressionInvocation
        function2: PostfixExpression
          operand2: SimpleIdentifier
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
          arguments2
            IntegerLiteral
              literal: 42
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_bangQuestionIndex() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a!?[0];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: PostfixExpression
          operand2: SimpleIdentifier
            token: a
          operator: !
        question: ?
        leftBracket: [
        index2: IntegerLiteral
          literal: 0
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_binary_expression_statement() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
D? foo(X? x) {
  X ?? x2;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: BinaryExpression
        leftOperand2: SimpleIdentifier
          token: X
        operator: ??
        rightOperand2: SimpleIdentifier
          token: x2
      semicolon: ;
  rightBracket: }
''');
  }

  void test_cascade_withNullCheck_indexExpression() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?..[27];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: CascadeExpression
        target2: SimpleIdentifier
          token: a
        cascadeSections2
          IndexExpression
            period: ?..
            leftBracket: [
            index2: IntegerLiteral
              literal: 27
            rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_cascade_withNullCheck_invalid() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() { a..[27]?..x; }
//                ^^^
// [diag.nullAwareCascadeOutOfOrder] The '?..' cascade operator must be first in the cascade sequence.
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: CascadeExpression
        target2: SimpleIdentifier
          token: a
        cascadeSections2
          IndexExpression
            period: ..
            leftBracket: [
            index2: IntegerLiteral
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?..foo();
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: CascadeExpression
        target2: SimpleIdentifier
          token: a
        cascadeSections2
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?..x27;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: CascadeExpression
        target2: SimpleIdentifier
          token: a
        cascadeSections2
          PropertyAccess
            operator: ?..
            propertyName: SimpleIdentifier
              token: x27
      semicolon: ;
  rightBracket: }
''');
  }

  void test_conditional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
D? foo(X? x) {
  X ? 7 : y;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: ConditionalExpression
        condition2: SimpleIdentifier
          token: X
        question: ?
        thenExpression2: IntegerLiteral
          literal: 7
        colon: :
        elseExpression2: SimpleIdentifier
          token: y
      semicolon: ;
  rightBracket: }
''');
  }

  void test_conditional_complex() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
D? foo(X? x) {
  X ? x2 = x + bar(7) : y;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: ConditionalExpression
        condition2: SimpleIdentifier
          token: X
        question: ?
        thenExpression2: AssignmentExpression
          leftHandSide2: SimpleIdentifier
            token: x2
          operator: =
          rightHandSide2: BinaryExpression
            leftOperand2: SimpleIdentifier
              token: x
            operator: +
            rightOperand2: MethodInvocation
              methodName: SimpleIdentifier
                token: bar
              argumentList: ArgumentList
                leftParenthesis: (
                arguments2
                  IntegerLiteral
                    literal: 7
                rightParenthesis: )
        colon: :
        elseExpression2: SimpleIdentifier
          token: y
      semicolon: ;
  rightBracket: }
''');
  }

  void test_conditional_error() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
D? foo(X? x) { X ? ? x2 = x + bar(7) : y; }
//                 ^
// [diag.missingIdentifier] Expected an identifier.
//                                      ^
// [diag.expectedToken] Expected to find ':'.
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: ConditionalExpression
        condition2: SimpleIdentifier
          token: X
        question: ?
        thenExpression2: ConditionalExpression
          condition2: SimpleIdentifier
            token: <empty> <synthetic>
          question: ?
          thenExpression2: AssignmentExpression
            leftHandSide2: SimpleIdentifier
              token: x2
            operator: =
            rightHandSide2: BinaryExpression
              leftOperand2: SimpleIdentifier
                token: x
              operator: +
              rightOperand2: MethodInvocation
                methodName: SimpleIdentifier
                  token: bar
                argumentList: ArgumentList
                  leftParenthesis: (
                  arguments2
                    IntegerLiteral
                      literal: 7
                  rightParenthesis: )
          colon: :
          elseExpression2: SimpleIdentifier
            token: y
        colon: : <synthetic>
        elseExpression2: SimpleIdentifier
          token: <empty> <synthetic>
      semicolon: ;
  rightBracket: }
''');
  }

  void test_conditional_simple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
D? foo(X? x) {
  X ? x2 = x : y;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: ConditionalExpression
        condition2: SimpleIdentifier
          token: X
        question: ?
        thenExpression2: AssignmentExpression
          leftHandSide2: SimpleIdentifier
            token: x2
          operator: =
          rightHandSide2: SimpleIdentifier
            token: x
        colon: :
        elseExpression2: SimpleIdentifier
          token: y
      semicolon: ;
  rightBracket: }
''');
  }

  void test_for() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for (int x = 0; x < 7; ++x) {}
}
''');
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
              initializer2: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: x
          operator: <
          rightOperand2: IntegerLiteral
            literal: 7
        rightSeparator: ;
        updaters2
          PrefixExpression
            operator: ++
            operand2: SimpleIdentifier
              token: x
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_for_conditional() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for (x ? y = 7 : y = 8; y < 10; ++y) {}
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ForStatement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForPartsWithExpression
        initialization2: ConditionalExpression
          condition2: SimpleIdentifier
            token: x
          question: ?
          thenExpression2: AssignmentExpression
            leftHandSide2: SimpleIdentifier
              token: y
            operator: =
            rightHandSide2: IntegerLiteral
              literal: 7
          colon: :
          elseExpression2: AssignmentExpression
            leftHandSide2: SimpleIdentifier
              token: y
            operator: =
            rightHandSide2: IntegerLiteral
              literal: 8
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: y
          operator: <
          rightOperand2: IntegerLiteral
            literal: 10
        rightSeparator: ;
        updaters2
          PrefixExpression
            operator: ++
            operand2: SimpleIdentifier
              token: y
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_for_nullable() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for (int? x = 0; x < 7; ++x) {}
}
''');
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
              initializer2: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: x
          operator: <
          rightOperand2: IntegerLiteral
            literal: 7
        rightSeparator: ;
        updaters2
          PrefixExpression
            operator: ++
            operand2: SimpleIdentifier
              token: x
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_foreach() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for (int x in [7]) {}
}
''');
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
        iterable2: ListLiteral
          leftBracket: [
          elements2
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for (int? x in [7, null]) {}
}
''');
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
        iterable2: ListLiteral
          leftBracket: [
          elements2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
+t{{r?this}}
// [diag.expectedExecutable][column 1][length 1] Expected a method, getter, setter or operator declaration.
// [diag.missingFunctionParameters][column 2][length 1] Functions must have an explicit list of parameters.
//    ^^^^
// [diag.expectedToken] Expected to find ';'.
//        ^
// [diag.expectedToken] Expected to find ':'.
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    Block
      leftBracket: {
      statements
        ExpressionStatement
          expression2: ConditionalExpression
            condition2: SimpleIdentifier
              token: r
            question: ?
            thenExpression2: ThisExpression
              thisKeyword: this
            colon: : <synthetic>
            elseExpression2: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
      rightBracket: }
  rightBracket: }
''');
  }

  void test_gft_nullable() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  C? Function() x = 7;
}
''');
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
            initializer2: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_gft_nullable_1() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  C Function()? x = 7;
}
''');
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
            initializer2: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_gft_nullable_2() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  C? Function()? x = 7;
}
''');
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
            initializer2: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_gft_nullable_3() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  C? Function()? Function()? x = 7;
}
''');
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
            initializer2: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_gft_nullable_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  C.a? Function()? x = 7;
}
''');
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
            initializer2: IntegerLiteral
              literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_indexed() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a[7];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: SimpleIdentifier
          token: a
        leftBracket: [
        index2: IntegerLiteral
          literal: 7
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_indexed_nullAware() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a?[7];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: SimpleIdentifier
          token: a
        question: ?
        leftBracket: [
        index2: IntegerLiteral
          literal: 7
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_is_nullable() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  x is String? ? (x + y) : z;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: ConditionalExpression
        condition2: IsExpression
          expression2: SimpleIdentifier
            token: x
          isOperator: is
          type: NamedType
            name: String
            question: ?
        question: ?
        thenExpression2: ParenthesizedExpression
          leftParenthesis: (
          expression2: BinaryExpression
            leftOperand2: SimpleIdentifier
              token: x
            operator: +
            rightOperand2: SimpleIdentifier
              token: y
          rightParenthesis: )
        colon: :
        elseExpression2: SimpleIdentifier
          token: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_is_nullable_parenthesis() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  (x is String?) ? (x + y) : z;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: ConditionalExpression
        condition2: ParenthesizedExpression
          leftParenthesis: (
          expression2: IsExpression
            expression2: SimpleIdentifier
              token: x
            isOperator: is
            type: NamedType
              name: String
              question: ?
          rightParenthesis: )
        question: ?
        thenExpression2: ParenthesizedExpression
          leftParenthesis: (
          expression2: BinaryExpression
            leftOperand2: SimpleIdentifier
              token: x
            operator: +
            rightOperand2: SimpleIdentifier
              token: y
          rightParenthesis: )
        colon: :
        elseExpression2: SimpleIdentifier
          token: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_late_as_identifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
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
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: MethodInvocation
        methodName: SimpleIdentifier
          token: print
        argumentList: ArgumentList
          leftParenthesis: (
          arguments2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
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
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: MethodInvocation
        methodName: SimpleIdentifier
          token: print
        argumentList: ArgumentList
          leftParenthesis: (
          arguments2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : x = o as String?, y = 0;
}
''');
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
              requiredPositionalFormalParameters
                RegularFormalParameter
                  type: NamedType
                    name: Object
                    question: ?
                  name: o
              rightParenthesis: )
            parameters(v1): FormalParameterList
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
                expression2: AsExpression
                  expression2: SimpleIdentifier
                    token: o
                  asOperator: as
                  type: NamedType
                    name: String
                    question: ?
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: y
                equals: =
                expression2: IntegerLiteral
                  literal: 0
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_nullableTypeInInitializerList_02() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : y = o is String? ? o.length : null, x = null;
}
''');
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
              requiredPositionalFormalParameters
                RegularFormalParameter
                  type: NamedType
                    name: Object
                    question: ?
                  name: o
              rightParenthesis: )
            parameters(v1): FormalParameterList
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
                expression2: ConditionalExpression
                  condition2: IsExpression
                    expression2: SimpleIdentifier
                      token: o
                    isOperator: is
                    type: NamedType
                      name: String
                      question: ?
                  question: ?
                  thenExpression2: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: o
                    period: .
                    identifier: SimpleIdentifier
                      token: length
                  colon: :
                  elseExpression2: NullLiteral
                    literal: null
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: x
                equals: =
                expression2: NullLiteral
                  literal: null
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_nullableTypeInInitializerList_03() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : y = o is String ? o.length : null, x = null;
}
''');
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
              requiredPositionalFormalParameters
                RegularFormalParameter
                  type: NamedType
                    name: Object
                    question: ?
                  name: o
              rightParenthesis: )
            parameters(v1): FormalParameterList
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
                expression2: ConditionalExpression
                  condition2: IsExpression
                    expression2: SimpleIdentifier
                      token: o
                    isOperator: is
                    type: NamedType
                      name: String
                  question: ?
                  thenExpression2: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: o
                    period: .
                    identifier: SimpleIdentifier
                      token: length
                  colon: :
                  elseExpression2: NullLiteral
                    literal: null
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: x
                equals: =
                expression2: NullLiteral
                  literal: null
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_nullCheck() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int? y) {
  var x = y!;
}
''');
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
            initializer2: PostfixExpression
              operand2: SimpleIdentifier
                token: y
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckAfterGetterAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g.x!.y + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PropertyAccess
                target2: PostfixExpression
                  operand2: PrefixedIdentifier
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
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckAfterMethodCall() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g.m()!.y + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PropertyAccess
                target2: PostfixExpression
                  operand2: MethodInvocation
                    target2: SimpleIdentifier
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
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckBeforeGetterAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g!.x + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PropertyAccess
                target2: PostfixExpression
                  operand2: SimpleIdentifier
                    token: g
                  operator: !
                operator: .
                propertyName: SimpleIdentifier
                  token: x
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckBeforeIndex() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  foo.bar!.baz[arg];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: PropertyAccess
          target2: PostfixExpression
            operand2: PrefixedIdentifier
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
        index2: SimpleIdentifier
          token: arg
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckBeforeMethodCall() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g!.m() + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: MethodInvocation
                target2: PostfixExpression
                  operand2: SimpleIdentifier
                    token: g
                  operator: !
                operator: .
                methodName: SimpleIdentifier
                  token: m
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckFunctionResult() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g()! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: MethodInvocation
                  methodName: SimpleIdentifier
                    token: g
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckIndexedValue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int? y) {
  var x = y[0]! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: IndexExpression
                  target2: SimpleIdentifier
                    token: y
                  leftBracket: [
                  index2: IntegerLiteral
                    literal: 0
                  rightBracket: ]
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckIndexedValue2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int? y) {
  var x = super.y[0]! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: IndexExpression
                  target2: PropertyAccess
                    target2: SuperExpression
                      superKeyword: super
                    operator: .
                    propertyName: SimpleIdentifier
                      token: y
                  leftBracket: [
                  index2: IntegerLiteral
                    literal: 0
                  rightBracket: ]
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckInExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int? y) {
  var x = y! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: SimpleIdentifier
                  token: y
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckMethodResult() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g.m()! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: MethodInvocation
                  target2: SimpleIdentifier
                    token: g
                  operator: .
                  methodName: SimpleIdentifier
                    token: m
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckMethodResult2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g?.m()! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: MethodInvocation
                  target2: SimpleIdentifier
                    token: g
                  operator: ?.
                  methodName: SimpleIdentifier
                    token: m
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckMethodResult3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = super.m()! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: MethodInvocation
                  target2: SuperExpression
                    superKeyword: super
                  operator: .
                  methodName: SimpleIdentifier
                    token: m
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnConstConstructor() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = const Foo()!;
}
''');
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
            initializer2: PostfixExpression
              operand2: InstanceCreationExpression
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = new Foo()!;
}
''');
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
            initializer2: PostfixExpression
              operand2: InstanceCreationExpression
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  obj![arg];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: PostfixExpression
          operand2: SimpleIdentifier
            token: obj
          operator: !
        leftBracket: [
        index2: SimpleIdentifier
          token: arg
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  obj![arg]![arg2];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: PostfixExpression
          operand2: IndexExpression
            target2: PostfixExpression
              operand2: SimpleIdentifier
                token: obj
              operator: !
            leftBracket: [
            index2: SimpleIdentifier
              token: arg
            rightBracket: ]
          operator: !
        leftBracket: [
        index2: SimpleIdentifier
          token: arg2
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  foo.bar![arg];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: PostfixExpression
          operand2: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: foo
            period: .
            identifier: SimpleIdentifier
              token: bar
          operator: !
        leftBracket: [
        index2: SimpleIdentifier
          token: arg
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex4() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  foo!.bar![arg];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: PostfixExpression
          operand2: PropertyAccess
            target2: PostfixExpression
              operand2: SimpleIdentifier
                token: foo
              operator: !
            operator: .
            propertyName: SimpleIdentifier
              token: bar
          operator: !
        leftBracket: [
        index2: SimpleIdentifier
          token: arg
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex5() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  foo.bar![arg]![arg2];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: PostfixExpression
          operand2: IndexExpression
            target2: PostfixExpression
              operand2: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo
                period: .
                identifier: SimpleIdentifier
                  token: bar
              operator: !
            leftBracket: [
            index2: SimpleIdentifier
              token: arg
            rightBracket: ]
          operator: !
        leftBracket: [
        index2: SimpleIdentifier
          token: arg2
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnIndex6() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  foo!.bar![arg]![arg2];
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: IndexExpression
        target2: PostfixExpression
          operand2: IndexExpression
            target2: PostfixExpression
              operand2: PropertyAccess
                target2: PostfixExpression
                  operand2: SimpleIdentifier
                    token: foo
                  operator: !
                operator: .
                propertyName: SimpleIdentifier
                  token: bar
              operator: !
            leftBracket: [
            index2: SimpleIdentifier
              token: arg
            rightBracket: ]
          operator: !
        leftBracket: [
        index2: SimpleIdentifier
          token: arg2
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralDouble() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = 1.2!;
}
''');
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
            initializer2: PostfixExpression
              operand2: DoubleLiteral
                literal: 1.2
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralInt() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = 0!;
}
''');
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
            initializer2: PostfixExpression
              operand2: IntegerLiteral
                literal: 0
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralList() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = [1, 2]!;
}
''');
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
            initializer2: PostfixExpression
              operand2: ListLiteral
                leftBracket: [
                elements2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = {1: 2}!;
}
''');
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
            initializer2: PostfixExpression
              operand2: SetOrMapLiteral
                leftBracket: {
                elements2
                  MapLiteralEntry
                    key2: IntegerLiteral
                      literal: 1
                    separator: :
                    value2: IntegerLiteral
                      literal: 2
                rightBracket: }
                isMap: false
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnLiteralSet() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = {1, 2}!;
}
''');
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
            initializer2: PostfixExpression
              operand2: SetOrMapLiteral
                leftBracket: {
                elements2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = "seven"!;
}
''');
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
            initializer2: PostfixExpression
              operand2: SimpleStringLiteral
                literal: "seven"
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnNull() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = null!;
}
''');
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
            initializer2: PostfixExpression
              operand2: NullLiteral
                literal: null
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnSend() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  obj!(arg);
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: FunctionExpressionInvocation
        function2: PostfixExpression
          operand2: SimpleIdentifier
            token: obj
          operator: !
        argumentList: ArgumentList
          leftParenthesis: (
          arguments2
            SimpleIdentifier
              token: arg
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnSend2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  obj!(arg)!(arg2);
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: FunctionExpressionInvocation
        function2: PostfixExpression
          operand2: FunctionExpressionInvocation
            function2: PostfixExpression
              operand2: SimpleIdentifier
                token: obj
              operator: !
            argumentList: ArgumentList
              leftParenthesis: (
              arguments2
                SimpleIdentifier
                  token: arg
              rightParenthesis: )
          operator: !
        argumentList: ArgumentList
          leftParenthesis: (
          arguments2
            SimpleIdentifier
              token: arg2
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnSymbol() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = #seven!;
}
''');
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
            initializer2: PostfixExpression
              operand2: SymbolLiteral
                poundSign: #
                components
                  seven
              operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckOnValue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(Point p) {
  var x = p.y! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: p
                  period: .
                  identifier: SimpleIdentifier
                    token: y
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckParenthesizedExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int? y) {
  var x = (y)! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: ParenthesizedExpression
                  leftParenthesis: (
                  expression2: SimpleIdentifier
                    token: y
                  rightParenthesis: )
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckPropertyAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g.p! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: g
                  period: .
                  identifier: SimpleIdentifier
                    token: p
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckPropertyAccess2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = g?.p! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: PropertyAccess
                  target2: SimpleIdentifier
                    token: g
                  operator: ?.
                  propertyName: SimpleIdentifier
                    token: p
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_nullCheckPropertyAccess3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  var x = super.p! + 7;
}
''');
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
            initializer2: BinaryExpression
              leftOperand2: PostfixExpression
                operand2: PropertyAccess
                  target2: SuperExpression
                    superKeyword: super
                  operator: .
                  propertyName: SimpleIdentifier
                    token: p
                operator: !
              operator: +
              rightOperand2: IntegerLiteral
                literal: 7
      semicolon: ;
  rightBracket: }
''');
  }

  void test_postfix_null_assertion_and_unary_prefix_operator_precedence() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  -x!;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: PrefixExpression
        operator: -
        operand2: PostfixExpression
          operand2: SimpleIdentifier
            token: x
          operator: !
      semicolon: ;
  rightBracket: }
''');
  }

  void test_postfix_null_assertion_of_postfix_expression() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  x++!;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: PostfixExpression
        operand2: PostfixExpression
          operand2: SimpleIdentifier
            token: x
          operator: ++
        operator: !
      semicolon: ;
  rightBracket: }
''');
  }
}
