// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StatementParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class StatementParserTest extends ParserDiagnosticsTest {
  void test_35177() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  (f)()<int>();
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
        function: FunctionExpressionInvocation
          function: ParenthesizedExpression
            leftParenthesis: (
            expression: SimpleIdentifier
              token: f
            rightParenthesis: )
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_invalid_typeArg_34850() {
    var parseResult = parseStringWithErrors(r'''
foo Future<List<int>> bar() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 11, 4),
      error(diag.missingFunctionParameters, 4, 6),
      error(diag.missingFunctionBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: foo
      name: Future
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: List
          rightBracket: >
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: bar
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_invalid_typeParamAnnotation() {
    var parseResult = parseStringWithErrors(r'''
main() { C<@Foo T> v; }
''');
    parseResult.assertErrors([error(diag.annotationOnTypeArgument, 11, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: C
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: T
                      rightBracket: >
                  variables
                    VariableDeclaration
                      name: v
                semicolon: ;
            rightBracket: }
''');
  }

  void test_invalid_typeParamAnnotation2() {
    var parseResult = parseStringWithErrors(r'''
main() { C<@Foo.bar(1) T> v; }
''');
    parseResult.assertErrors([error(diag.annotationOnTypeArgument, 11, 11)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: C
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: T
                      rightBracket: >
                  variables
                    VariableDeclaration
                      name: v
                semicolon: ;
            rightBracket: }
''');
  }

  void test_invalid_typeParamAnnotation3() {
    var parseResult = parseStringWithErrors(r'''
main() {
  C<@Foo.bar(const [], const [1], const{"":r""}, 0xFF + 2, .3, 4.5) T,
    F Function<G>(int, String, {Bar b}),
    void Function<H>(int i, [String j, K]),
    A<B<C>>,
    W<X<Y<Z>>>
  > v;
}
''');
    parseResult.assertErrors([error(diag.annotationOnTypeArgument, 13, 63)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: C
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: T
                        GenericFunctionType
                          returnType: NamedType
                            name: F
                          functionKeyword: Function
                          typeParameters: TypeParameterList
                            leftBracket: <
                            typeParameters
                              TypeParameter
                                name: G
                            rightBracket: >
                          parameters: FormalParameterList
                            leftParenthesis: (
                            parameter: RegularFormalParameter
                              type: NamedType
                                name: int
                            parameter: RegularFormalParameter
                              type: NamedType
                                name: String
                            leftDelimiter: {
                            parameter: RegularFormalParameter
                              type: NamedType
                                name: Bar
                              name: b
                            rightDelimiter: }
                            rightParenthesis: )
                        GenericFunctionType
                          returnType: NamedType
                            name: void
                          functionKeyword: Function
                          typeParameters: TypeParameterList
                            leftBracket: <
                            typeParameters
                              TypeParameter
                                name: H
                            rightBracket: >
                          parameters: FormalParameterList
                            leftParenthesis: (
                            parameter: RegularFormalParameter
                              type: NamedType
                                name: int
                              name: i
                            leftDelimiter: [
                            parameter: RegularFormalParameter
                              type: NamedType
                                name: String
                              name: j
                            parameter: RegularFormalParameter
                              type: NamedType
                                name: K
                            rightDelimiter: ]
                            rightParenthesis: )
                        NamedType
                          name: A
                          typeArguments: TypeArgumentList
                            leftBracket: <
                            arguments
                              NamedType
                                name: B
                                typeArguments: TypeArgumentList
                                  leftBracket: <
                                  arguments
                                    NamedType
                                      name: C
                                  rightBracket: >
                            rightBracket: >
                        NamedType
                          name: W
                          typeArguments: TypeArgumentList
                            leftBracket: <
                            arguments
                              NamedType
                                name: X
                                typeArguments: TypeArgumentList
                                  leftBracket: <
                                  arguments
                                    NamedType
                                      name: Y
                                      typeArguments: TypeArgumentList
                                        leftBracket: <
                                        arguments
                                          NamedType
                                            name: Z
                                        rightBracket: >
                                  rightBracket: >
                            rightBracket: >
                      rightBracket: >
                  variables
                    VariableDeclaration
                      name: v
                semicolon: ;
            rightBracket: }
''');
  }

  void test_parseAssertStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  assert(x);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    AssertStatement
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
      rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseAssertStatement_messageLowPrecedence() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  assert(x, throw "foo");
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    AssertStatement
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
      comma: ,
      message: ThrowExpression
        throwKeyword: throw
        expression: SimpleStringLiteral
          literal: "foo"
      rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseAssertStatement_messageString() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  assert(x, "foo");
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    AssertStatement
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
      comma: ,
      message: SimpleStringLiteral
        literal: "foo"
      rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseAssertStatement_trailingComma_message() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  assert(x, "m");
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    AssertStatement
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
      comma: ,
      message: SimpleStringLiteral
        literal: "m"
      rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseAssertStatement_trailingComma_noMessage() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  assert(x);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    AssertStatement
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
      rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseBlock_empty() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    Block
      leftBracket: {
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseBlock_nonEmpty() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  {
    ;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    Block
      leftBracket: {
      statements
        EmptyStatement
          semicolon: ;
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseBreakStatement_label() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  foo:
  while (true) {
    break foo;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    LabeledStatement
      labels
        Label
          name: foo
          colon: :
      statement: WhileStatement
        whileKeyword: while
        leftParenthesis: (
        condition: BooleanLiteral
          literal: true
        rightParenthesis: )
        body: Block
          leftBracket: {
          statements
            BreakStatement
              breakKeyword: break
              label: LabelReference
                name: foo
              semicolon: ;
          rightBracket: }
  rightBracket: }
''');
  }

  void test_parseBreakStatement_noLabel() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  while (true) {
    break;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    WhileStatement
      whileKeyword: while
      leftParenthesis: (
      condition: BooleanLiteral
        literal: true
      rightParenthesis: )
      body: Block
        leftBracket: {
        statements
          BreakStatement
            breakKeyword: break
            semicolon: ;
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseContinueStatement_label() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  foo:
  while (true) {
    continue foo;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    LabeledStatement
      labels
        Label
          name: foo
          colon: :
      statement: WhileStatement
        whileKeyword: while
        leftParenthesis: (
        condition: BooleanLiteral
          literal: true
        rightParenthesis: )
        body: Block
          leftBracket: {
          statements
            ContinueStatement
              continueKeyword: continue
              label: LabelReference
                name: foo
              semicolon: ;
          rightBracket: }
  rightBracket: }
''');
  }

  void test_parseContinueStatement_noLabel() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  while (true) {
    continue;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    WhileStatement
      whileKeyword: while
      leftParenthesis: (
      condition: BooleanLiteral
        literal: true
      rightParenthesis: )
      body: Block
        leftBracket: {
        statements
          ContinueStatement
            continueKeyword: continue
            semicolon: ;
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseDoStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  do {} while (x);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    DoStatement
      doKeyword: do
      body: Block
        leftBracket: {
        rightBracket: }
      whileKeyword: while
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
      rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseElseAlone() {
    var parseResult = parseStringWithErrors(r'''
main() { else return 0; } 
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 7, 1),
      error(diag.missingIdentifier, 9, 4),
      error(diag.unexpectedToken, 9, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                expression: IntegerLiteral
                  literal: 0
                semicolon: ;
            rightBracket: }
''');
  }

  void test_parseEmptyStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  ;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    EmptyStatement
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseForStatement_each_await() {
    var parseResult = parseStringWithErrors(r'''
void f() async {
  $code
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 5)]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: SimpleIdentifier
        token: $code
      semicolon: ; <synthetic>
  rightBracket: }
''');
  }

  void test_parseForStatement_each_await2() {
    var parseResult = parseStringWithErrors(r'''
void f() async {
  await for (element in list) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ForStatement
      awaitKeyword: await
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithIdentifier
        identifier: SimpleIdentifier
          token: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_finalExternal() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (final external in list) {}
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
          keyword: final
          name: external
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_finalRequired() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (final required in list) {}
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
          keyword: final
          name: required
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_genericFunctionType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (void Function<T>(T) element in list) {}
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
          type: GenericFunctionType
            returnType: NamedType
              name: void
            functionKeyword: Function
            typeParameters: TypeParameterList
              leftBracket: <
              typeParameters
                TypeParameter
                  name: T
              rightBracket: >
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: T
              rightParenthesis: )
          name: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_genericFunctionType2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (void Function<T>(T) element in list) {}
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
          type: GenericFunctionType
            returnType: NamedType
              name: void
            functionKeyword: Function
            typeParameters: TypeParameterList
              leftBracket: <
              typeParameters
                TypeParameter
                  name: T
              rightBracket: >
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: T
              rightParenthesis: )
          name: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_identifier() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (element in list) {}
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
      forLoopParts: ForEachPartsWithIdentifier
        identifier: SimpleIdentifier
          token: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_identifier2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (element in list) {}
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
      forLoopParts: ForEachPartsWithIdentifier
        identifier: SimpleIdentifier
          token: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_noType_metadata() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (@A var element in list) {}
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
          metadata
            Annotation
              atSign: @
              name: SimpleIdentifier
                token: A
          keyword: var
          name: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_noType_metadata2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (@A var element in list) {}
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
          metadata
            Annotation
              atSign: @
              name: SimpleIdentifier
                token: A
          keyword: var
          name: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_type() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (A element in list) {}
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
            name: A
          name: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_type2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (A element in list) {}
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
            name: A
          name: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_var() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var element in list) {}
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
          keyword: var
          name: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_each_var2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var element in list) {}
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
          keyword: var
          name: element
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_c() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (; i < count;) {}
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
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_c2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (; i < count;) {}
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
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_cu() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (; i < count; i++) {}
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
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_cu2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (; i < count; i++) {}
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
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_ecu() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (i--; i < count; i++) {}
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
        initialization: PostfixExpression
          operand: SimpleIdentifier
            token: i
          operator: --
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_ecu2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (i--; i < count; i++) {}
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
        initialization: PostfixExpression
          operand: SimpleIdentifier
            token: i
          operator: --
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_i() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var i = 0; ;) {}
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
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        rightSeparator: ;
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_i2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var i = 0; ;) {}
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
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        rightSeparator: ;
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_i_withMetadata() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (@A var i = 0; ;) {}
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
          metadata
            Annotation
              atSign: @
              name: SimpleIdentifier
                token: A
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        rightSeparator: ;
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_i_withMetadata2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (@A var i = 0; ;) {}
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
          metadata
            Annotation
              atSign: @
              name: SimpleIdentifier
                token: A
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        rightSeparator: ;
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_ic() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var i = 0; i < count;) {}
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
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_ic2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var i = 0; i < count;) {}
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
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_icu() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var i = 0; i < count; i++) {}
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
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_icu2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var i = 0; i < count; i++) {}
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
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: count
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_iicuu() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (int i = 0, j = count; i < j; i++, j--) {}
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
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
            VariableDeclaration
              name: j
              equals: =
              initializer: SimpleIdentifier
                token: count
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: j
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
          PostfixExpression
            operand: SimpleIdentifier
              token: j
            operator: --
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_iicuu2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (int i = 0, j = count; i < j; i++, j--) {}
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
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
            VariableDeclaration
              name: j
              equals: =
              initializer: SimpleIdentifier
                token: count
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: i
          operator: <
          rightOperand: SimpleIdentifier
            token: j
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
          PostfixExpression
            operand: SimpleIdentifier
              token: j
            operator: --
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_iu() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var i = 0; ; i++) {}
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
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_iu2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var i = 0; ; i++) {}
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
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_u() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (; ; i++) {}
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
        leftSeparator: ;
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseForStatement_loop_u2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (; ; i++) {}
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
        leftSeparator: ;
        rightSeparator: ;
        updaters
          PostfixExpression
            operand: SimpleIdentifier
              token: i
            operator: ++
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseFunctionDeclarationStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void f(int p) => p * 2;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        returnType: NamedType
          name: void
        name: f
        functionExpression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: int
              name: p
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: BinaryExpression
              leftOperand: SimpleIdentifier
                token: p
              operator: *
              rightOperand: IntegerLiteral
                literal: 2
            semicolon: ;
  rightBracket: }
''');
  }

  void test_parseFunctionDeclarationStatement_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  E f<E>(E p) => p * 2;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        returnType: NamedType
          name: E
        name: f
        functionExpression: FunctionExpression
          typeParameters: TypeParameterList
            leftBracket: <
            typeParameters
              TypeParameter
                name: E
            rightBracket: >
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: E
              name: p
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: BinaryExpression
              leftOperand: SimpleIdentifier
                token: p
              operator: *
              rightOperand: IntegerLiteral
                literal: 2
            semicolon: ;
  rightBracket: }
''');
  }

  void test_parseFunctionDeclarationStatement_typeParameters_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  f<E>(E p) => p * 2;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        name: f
        functionExpression: FunctionExpression
          typeParameters: TypeParameterList
            leftBracket: <
            typeParameters
              TypeParameter
                name: E
            rightBracket: >
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: E
              name: p
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: BinaryExpression
              leftOperand: SimpleIdentifier
                token: p
              operator: *
              rightOperand: IntegerLiteral
                literal: 2
            semicolon: ;
  rightBracket: }
''');
  }

  void test_parseIfStatement_else_block() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  if (x) {
  } else {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    IfStatement
      ifKeyword: if
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
      rightParenthesis: )
      thenStatement: Block
        leftBracket: {
        rightBracket: }
      elseKeyword: else
      elseStatement: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseIfStatement_else_emptyStatements() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  if (true)
    ;
  else
    ;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    IfStatement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenStatement: EmptyStatement
        semicolon: ;
      elseKeyword: else
      elseStatement: EmptyStatement
        semicolon: ;
  rightBracket: }
''');
  }

  void test_parseIfStatement_else_statement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  if (x)
    f(x);
  else
    f(y);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    IfStatement
      ifKeyword: if
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
      rightParenthesis: )
      thenStatement: ExpressionStatement
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: f
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: x
            rightParenthesis: )
        semicolon: ;
      elseKeyword: else
      elseStatement: ExpressionStatement
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: f
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: y
            rightParenthesis: )
        semicolon: ;
  rightBracket: }
''');
  }

  void test_parseIfStatement_noElse_block() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  if (x) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    IfStatement
      ifKeyword: if
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
      rightParenthesis: )
      thenStatement: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseIfStatement_noElse_statement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  if (x) f(x);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    IfStatement
      ifKeyword: if
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
      rightParenthesis: )
      thenStatement: ExpressionStatement
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: f
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: x
            rightParenthesis: )
        semicolon: ;
  rightBracket: }
''');
  }

  void test_parseLocalVariable_external() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  external int i;
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 13, 8)]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: i
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_const_list_empty() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  const [];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: ListLiteral
        constKeyword: const
        leftBracket: [
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_const_list_nonEmpty() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  const [1, 2];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: ListLiteral
        constKeyword: const
        leftBracket: [
        elements
          IntegerLiteral
            literal: 1
          IntegerLiteral
            literal: 2
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_const_map_empty() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  const {};
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: SetOrMapLiteral
        constKeyword: const
        leftBracket: {
        rightBracket: }
        isMap: false
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_const_map_nonEmpty() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  const {'a': 1};
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: SetOrMapLiteral
        constKeyword: const
        leftBracket: {
        elements
          MapLiteralEntry
            key: SimpleStringLiteral
              literal: 'a'
            separator: :
            value: IntegerLiteral
              literal: 1
        rightBracket: }
        isMap: false
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_const_object() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  const A();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: InstanceCreationExpression
        keyword: const
        constructorName: ConstructorName
          type: NamedType
            name: A
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  const A<B>.c();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: InstanceCreationExpression
        keyword: const
        constructorName: ConstructorName
          type: NamedType
            name: A
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: B
              rightBracket: >
          period: .
          name: SimpleIdentifier
            token: c
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters_34403() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  const A<B>.c<C>();
}
''');
    parseResult.assertErrors([error(diag.constructorWithTypeArguments, 24, 1)]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: InstanceCreationExpression
        keyword: const
        constructorName: ConstructorName
          type: NamedType
            name: A
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: B
              rightBracket: >
          period: .
          name: SimpleIdentifier
            token: c
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: C
          rightBracket: >
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_constructorInvocation() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  new C().m();
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
        target: InstanceCreationExpression
          keyword: new
          constructorName: ConstructorName
            type: NamedType
              name: C
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
        operator: .
        methodName: SimpleIdentifier
          token: m
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_false() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  false;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: BooleanLiteral
        literal: false
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_functionDeclaration() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  f() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        name: f
        functionExpression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: BlockFunctionBody
            block: Block
              leftBracket: {
              rightBracket: }
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_functionDeclaration_arguments() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  f(void g()) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        name: f
        functionExpression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: void
              name: g
              functionTypedSuffix: FunctionTypedFormalParameterSuffix
                formalParameters: FormalParameterList
                  leftParenthesis: (
                  rightParenthesis: )
            rightParenthesis: )
          body: BlockFunctionBody
            block: Block
              leftBracket: {
              rightBracket: }
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_functionExpressionIndex() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  () {}[0] = null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: IndexExpression
          target: FunctionExpression
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
          leftBracket: [
          index: IntegerLiteral
            literal: 0
          rightBracket: ]
        operator: =
        rightHandSide: NullLiteral
          literal: null
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_functionInvocation() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  f();
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
          token: f
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_invokeFunctionExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  (a) {
    return a + a;
  }(3);
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
        function: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              name: a
            rightParenthesis: )
          body: BlockFunctionBody
            block: Block
              leftBracket: {
              statements
                ReturnStatement
                  returnKeyword: return
                  expression: BinaryExpression
                    leftOperand: SimpleIdentifier
                      token: a
                    operator: +
                    rightOperand: SimpleIdentifier
                      token: a
                  semicolon: ;
              rightBracket: }
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 3
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_localFunction_gftReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int Function(int) f(String s) => null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        returnType: GenericFunctionType
          returnType: NamedType
            name: int
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: int
            rightParenthesis: )
        name: f
        functionExpression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: String
              name: s
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: NullLiteral
              literal: null
            semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_null() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: NullLiteral
        literal: null
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  library.getName();
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
        target: SimpleIdentifier
          token: library
        operator: .
        methodName: SimpleIdentifier
          token: getName
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_true() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  true;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: BooleanLiteral
        literal: true
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_typeCast() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  double.nan as num;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AsExpression
        expression: PrefixedIdentifier
          prefix: SimpleIdentifier
            token: double
          period: .
          identifier: SimpleIdentifier
            token: nan
        asOperator: as
        type: NamedType
          name: num
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_variableDeclaration_final_namedFunction() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  final int Function = 0;
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
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: Function
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_variableDeclaration_gftType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int Function(int) v;
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
            name: int
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: int
            rightParenthesis: )
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void
  test_parseNonLabeledStatement_variableDeclaration_gftType_functionReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  Function Function(int x1, {Function x}) Function<B extends core.int>(int x) v;
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
              name: Function
            functionKeyword: Function
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: x1
              leftDelimiter: {
              parameter: RegularFormalParameter
                type: NamedType
                  name: Function
                name: x
              rightDelimiter: }
              rightParenthesis: )
          functionKeyword: Function
          typeParameters: TypeParameterList
            leftBracket: <
            typeParameters
              TypeParameter
                name: B
                extendsKeyword: extends
                bound: NamedType
                  importPrefix: ImportPrefixReference
                    name: core
                    period: .
                  name: int
            rightBracket: >
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: int
              name: x
            rightParenthesis: )
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void
  test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  Function(int) Function(int) v;
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
            functionKeyword: Function
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
              rightParenthesis: )
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: int
            rightParenthesis: )
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void
  test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int Function(int) Function(int) v;
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
              name: int
            functionKeyword: Function
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
              rightParenthesis: )
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: int
            rightParenthesis: )
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void
  test_parseNonLabeledStatement_variableDeclaration_gftType_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  Function(int) v;
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
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: int
            rightParenthesis: )
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_variableDeclaration_gftType_returnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int Function<T>() v;
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
            name: int
          functionKeyword: Function
          typeParameters: TypeParameterList
            leftBracket: <
            typeParameters
              TypeParameter
                name: T
            rightBracket: >
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void
  test_parseNonLabeledStatement_variableDeclaration_gftType_voidReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void Function() v;
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
            name: void
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  C<T> v;
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
          name: C
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: T
            rightBracket: >
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  C<T /* ignored comment */> v;
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
          name: C
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: T
            rightBracket: >
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam3() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  C<T Function(String s)> v;
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
          name: C
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              GenericFunctionType
                returnType: NamedType
                  name: T
                functionKeyword: Function
                parameters: FormalParameterList
                  leftParenthesis: (
                  parameter: RegularFormalParameter
                    type: NamedType
                      name: String
                    name: s
                  rightParenthesis: )
            rightBracket: >
        variables
          VariableDeclaration
            name: v
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseStatement_emptyTypeArgumentList() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  C<> c;
}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 15, 1)]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: C
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: <empty> <synthetic>
            rightBracket: >
        variables
          VariableDeclaration
            name: c
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseStatement_function_gftReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void Function<A>(core.List<core.int> x) m() => null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        returnType: GenericFunctionType
          returnType: NamedType
            name: void
          functionKeyword: Function
          typeParameters: TypeParameterList
            leftBracket: <
            typeParameters
              TypeParameter
                name: A
            rightBracket: >
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: core
                  period: .
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      importPrefix: ImportPrefixReference
                        name: core
                        period: .
                      name: int
                  rightBracket: >
              name: x
            rightParenthesis: )
        name: m
        functionExpression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: NullLiteral
              literal: null
            semicolon: ;
  rightBracket: }
''');
  }

  void test_parseStatement_functionDeclaration_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  true;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: BooleanLiteral
        literal: true
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseStatement_functionDeclaration_noReturnType_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  f<E>(a, b) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        name: f
        functionExpression: FunctionExpression
          typeParameters: TypeParameterList
            leftBracket: <
            typeParameters
              TypeParameter
                name: E
            rightBracket: >
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              name: a
            parameter: RegularFormalParameter
              name: b
            rightParenthesis: )
          body: BlockFunctionBody
            block: Block
              leftBracket: {
              rightBracket: }
  rightBracket: }
''');
  }

  void test_parseStatement_functionDeclaration_returnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int f(a, b) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        returnType: NamedType
          name: int
        name: f
        functionExpression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              name: a
            parameter: RegularFormalParameter
              name: b
            rightParenthesis: )
          body: BlockFunctionBody
            block: Block
              leftBracket: {
              rightBracket: }
  rightBracket: }
''');
  }

  void test_parseStatement_functionDeclaration_returnType_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int f<E>(a, b) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    FunctionDeclarationStatement
      functionDeclaration: FunctionDeclaration
        returnType: NamedType
          name: int
        name: f
        functionExpression: FunctionExpression
          typeParameters: TypeParameterList
            leftBracket: <
            typeParameters
              TypeParameter
                name: E
            rightBracket: >
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              name: a
            parameter: RegularFormalParameter
              name: b
            rightParenthesis: )
          body: BlockFunctionBody
            block: Block
              leftBracket: {
              rightBracket: }
  rightBracket: }
''');
  }

  void test_parseStatement_multipleLabels() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  l:
  m:
  return x;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    LabeledStatement
      labels
        Label
          name: l
          colon: :
        Label
          name: m
          colon: :
      statement: ReturnStatement
        returnKeyword: return
        expression: SimpleIdentifier
          token: x
        semicolon: ;
  rightBracket: }
''');
  }

  void test_parseStatement_noLabels() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return x;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: SimpleIdentifier
        token: x
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseStatement_singleLabel() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  l:
  return x;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    LabeledStatement
      labels
        Label
          name: l
          colon: :
      statement: ReturnStatement
        returnKeyword: return
        expression: SimpleIdentifier
          token: x
        semicolon: ;
  rightBracket: }
''');
  }

  void test_parseSwitchStatement_case() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {
    case 1:
      return "I";
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    SwitchStatement
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
      rightParenthesis: )
      leftBracket: {
      members
        SwitchPatternCase
          keyword: case
          guardedPattern: GuardedPattern
            pattern: ConstantPattern
              expression: IntegerLiteral
                literal: 1
          colon: :
          statements
            ReturnStatement
              returnKeyword: return
              expression: SimpleStringLiteral
                literal: "I"
              semicolon: ;
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseSwitchStatement_empty() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    SwitchStatement
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
      rightParenthesis: )
      leftBracket: {
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseSwitchStatement_labeledCase() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {
    l1:
    l2:
    l3:
    case (1):
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    SwitchStatement
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
      rightParenthesis: )
      leftBracket: {
      members
        SwitchPatternCase
          labels
            Label
              name: l1
              colon: :
            Label
              name: l2
              colon: :
            Label
              name: l3
              colon: :
          keyword: case
          guardedPattern: GuardedPattern
            pattern: ParenthesizedPattern
              leftParenthesis: (
              pattern: ConstantPattern
                expression: IntegerLiteral
                  literal: 1
              rightParenthesis: )
          colon: :
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseSwitchStatement_labeledCase2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {
    l1:
    case 0:
    l2:
    case 1:
      return;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    SwitchStatement
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
      rightParenthesis: )
      leftBracket: {
      members
        SwitchPatternCase
          labels
            Label
              name: l1
              colon: :
          keyword: case
          guardedPattern: GuardedPattern
            pattern: ConstantPattern
              expression: IntegerLiteral
                literal: 0
          colon: :
        SwitchPatternCase
          labels
            Label
              name: l2
              colon: :
          keyword: case
          guardedPattern: GuardedPattern
            pattern: ConstantPattern
              expression: IntegerLiteral
                literal: 1
          colon: :
          statements
            ReturnStatement
              returnKeyword: return
              semicolon: ;
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseSwitchStatement_labeledDefault() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {
    l1:
    l2:
    l3:
    default:
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    SwitchStatement
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
      rightParenthesis: )
      leftBracket: {
      members
        SwitchDefault
          labels
            Label
              name: l1
              colon: :
            Label
              name: l2
              colon: :
            Label
              name: l3
              colon: :
          keyword: default
          colon: :
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseSwitchStatement_labeledDefault2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {
    l1:
    case 0:
    l2:
    default:
      return;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    SwitchStatement
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
      rightParenthesis: )
      leftBracket: {
      members
        SwitchPatternCase
          labels
            Label
              name: l1
              colon: :
          keyword: case
          guardedPattern: GuardedPattern
            pattern: ConstantPattern
              expression: IntegerLiteral
                literal: 0
          colon: :
        SwitchDefault
          labels
            Label
              name: l2
              colon: :
          keyword: default
          colon: :
          statements
            ReturnStatement
              returnKeyword: return
              semicolon: ;
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseSwitchStatement_labeledStatementInCase() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {
    case 0:
      f();
      l1:
      g();
      break;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    SwitchStatement
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
      rightParenthesis: )
      leftBracket: {
      members
        SwitchPatternCase
          keyword: case
          guardedPattern: GuardedPattern
            pattern: ConstantPattern
              expression: IntegerLiteral
                literal: 0
          colon: :
          statements
            ExpressionStatement
              expression: MethodInvocation
                methodName: SimpleIdentifier
                  token: f
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
              semicolon: ;
            LabeledStatement
              labels
                Label
                  name: l1
                  colon: :
              statement: ExpressionStatement
                expression: MethodInvocation
                  methodName: SimpleIdentifier
                    token: g
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                semicolon: ;
            BreakStatement
              breakKeyword: break
              semicolon: ;
      rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_catch() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} catch (e) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          catchKeyword: catch
          leftParenthesis: (
          exceptionParameter: CatchClauseParameter
            name: e
          rightParenthesis: )
          body: Block
            leftBracket: {
            rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_catch_error_invalidCatchParam() {
    var parseResult = parseStringWithErrors(r'''
main() { try {} catch (int e) { } }
''');
    parseResult.assertErrors([error(diag.catchSyntax, 27, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: int
                    comma: , <synthetic>
                    stackTraceParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_parseTryStatement_catch_error_missingCatchParam() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} catch () {}
}
''');
    parseResult.assertErrors([error(diag.catchSyntax, 27, 1)]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          catchKeyword: catch
          leftParenthesis: (
          exceptionParameter: CatchClauseParameter
            name: <empty> <synthetic>
          rightParenthesis: )
          body: Block
            leftBracket: {
            rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_catch_error_missingCatchParen() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} catch {}
}
''');
    parseResult.assertErrors([error(diag.catchSyntax, 26, 1)]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          catchKeyword: catch
          leftParenthesis: ( <synthetic>
          exceptionParameter: CatchClauseParameter
            name: <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          body: Block
            leftBracket: {
            rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_catch_error_missingCatchTrace() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} catch (e,) {}
}
''');
    parseResult.assertErrors([error(diag.catchSyntax, 29, 1)]);
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          catchKeyword: catch
          leftParenthesis: (
          exceptionParameter: CatchClauseParameter
            name: e
          comma: ,
          stackTraceParameter: CatchClauseParameter
            name: <empty> <synthetic>
          rightParenthesis: )
          body: Block
            leftBracket: {
            rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_catch_finally() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} catch (e, s) {
  } finally {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          catchKeyword: catch
          leftParenthesis: (
          exceptionParameter: CatchClauseParameter
            name: e
          comma: ,
          stackTraceParameter: CatchClauseParameter
            name: s
          rightParenthesis: )
          body: Block
            leftBracket: {
            rightBracket: }
      finallyKeyword: finally
      finallyBlock: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_finally() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} finally {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      finallyKeyword: finally
      finallyBlock: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_multiple() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} on NPE catch (e) {
  } on Error {
  } catch (e) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          onKeyword: on
          exceptionType: NamedType
            name: NPE
          catchKeyword: catch
          leftParenthesis: (
          exceptionParameter: CatchClauseParameter
            name: e
          rightParenthesis: )
          body: Block
            leftBracket: {
            rightBracket: }
        CatchClause
          onKeyword: on
          exceptionType: NamedType
            name: Error
          body: Block
            leftBracket: {
            rightBracket: }
        CatchClause
          catchKeyword: catch
          leftParenthesis: (
          exceptionParameter: CatchClauseParameter
            name: e
          rightParenthesis: )
          body: Block
            leftBracket: {
            rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_on() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} on Error {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          onKeyword: on
          exceptionType: NamedType
            name: Error
          body: Block
            leftBracket: {
            rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_on_catch() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} on Error catch (e, s) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          onKeyword: on
          exceptionType: NamedType
            name: Error
          catchKeyword: catch
          leftParenthesis: (
          exceptionParameter: CatchClauseParameter
            name: e
          comma: ,
          stackTraceParameter: CatchClauseParameter
            name: s
          rightParenthesis: )
          body: Block
            leftBracket: {
            rightBracket: }
  rightBracket: }
''');
  }

  void test_parseTryStatement_on_catch_finally() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {} on Error catch (e, s) {
  } finally {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    TryStatement
      tryKeyword: try
      body: Block
        leftBracket: {
        rightBracket: }
      catchClauses
        CatchClause
          onKeyword: on
          exceptionType: NamedType
            name: Error
          catchKeyword: catch
          leftParenthesis: (
          exceptionParameter: CatchClauseParameter
            name: e
          comma: ,
          stackTraceParameter: CatchClauseParameter
            name: s
          rightParenthesis: )
          body: Block
            leftBracket: {
            rightBracket: }
      finallyKeyword: finally
      finallyBlock: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseVariableDeclaration_equals_builtIn() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int set = 0;
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
          name: int
        variables
          VariableDeclaration
            name: set
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseVariableDeclarationListAfterMetadata_const_noType() {
    var parseResult = parseStringWithErrors(r'''
var x = null;
const a = 0;
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.unit.declarations.last
                as TopLevelVariableDeclaration)
            .variables;
    assertParsedNodeText(node, r'''
VariableDeclarationList
  keyword: const
  variables
    VariableDeclaration
      name: a
      equals: =
      initializer: IntegerLiteral
        literal: 0
''');
  }

  void test_parseVariableDeclarationListAfterMetadata_const_type() {
    var parseResult = parseStringWithErrors(r'''
var x = null;
const A a;
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.unit.declarations.last
                as TopLevelVariableDeclaration)
            .variables;
    assertParsedNodeText(node, r'''
VariableDeclarationList
  keyword: const
  type: NamedType
    name: A
  variables
    VariableDeclaration
      name: a
''');
  }

  void test_parseVariableDeclarationListAfterMetadata_final_noType() {
    var parseResult = parseStringWithErrors(r'''
var x = null;
final a;
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.unit.declarations.last
                as TopLevelVariableDeclaration)
            .variables;
    assertParsedNodeText(node, r'''
VariableDeclarationList
  keyword: final
  variables
    VariableDeclaration
      name: a
''');
  }

  void test_parseVariableDeclarationListAfterMetadata_final_type() {
    var parseResult = parseStringWithErrors(r'''
var x = null;
final A a;
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.unit.declarations.last
                as TopLevelVariableDeclaration)
            .variables;
    assertParsedNodeText(node, r'''
VariableDeclarationList
  keyword: final
  type: NamedType
    name: A
  variables
    VariableDeclaration
      name: a
''');
  }

  void test_parseVariableDeclarationListAfterMetadata_type_multiple() {
    var parseResult = parseStringWithErrors(r'''
var x = null;
A a, b, c;
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.unit.declarations.last
                as TopLevelVariableDeclaration)
            .variables;
    assertParsedNodeText(node, r'''
VariableDeclarationList
  type: NamedType
    name: A
  variables
    VariableDeclaration
      name: a
    VariableDeclaration
      name: b
    VariableDeclaration
      name: c
''');
  }

  void test_parseVariableDeclarationListAfterMetadata_type_single() {
    var parseResult = parseStringWithErrors(r'''
var x = null;
A a;
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.unit.declarations.last
                as TopLevelVariableDeclaration)
            .variables;
    assertParsedNodeText(node, r'''
VariableDeclarationList
  type: NamedType
    name: A
  variables
    VariableDeclaration
      name: a
''');
  }

  void test_parseVariableDeclarationListAfterMetadata_var_multiple() {
    var parseResult = parseStringWithErrors(r'''
var x = null;
var a, b, c;
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.unit.declarations.last
                as TopLevelVariableDeclaration)
            .variables;
    assertParsedNodeText(node, r'''
VariableDeclarationList
  keyword: var
  variables
    VariableDeclaration
      name: a
    VariableDeclaration
      name: b
    VariableDeclaration
      name: c
''');
  }

  void test_parseVariableDeclarationListAfterMetadata_var_single() {
    var parseResult = parseStringWithErrors(r'''
var x = null;
var a;
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.unit.declarations.last
                as TopLevelVariableDeclaration)
            .variables;
    assertParsedNodeText(node, r'''
VariableDeclarationList
  keyword: var
  variables
    VariableDeclaration
      name: a
''');
  }

  void test_parseVariableDeclarationStatementAfterMetadata_multiple() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x, y, z;
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
          VariableDeclaration
            name: y
          VariableDeclaration
            name: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseVariableDeclarationStatementAfterMetadata_single() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  var x;
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
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseWhileStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  while (x) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    WhileStatement
      whileKeyword: while
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
  rightBracket: }
''');
  }

  void test_parseYieldStatement_each() {
    var parseResult = parseStringWithErrors(r'''
void f() async* {
  yield* x;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    YieldStatement
      yieldKeyword: yield
      star: *
      expression: SimpleIdentifier
        token: x
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseYieldStatement_normal() {
    var parseResult = parseStringWithErrors(r'''
void f() async* {
  yield x;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    YieldStatement
      yieldKeyword: yield
      expression: SimpleIdentifier
        token: x
      semicolon: ;
  rightBracket: }
''');
  }

  void test_partial_typeArg1_34850() {
    var parseResult = parseStringWithErrors(r'''
<bar<
''');
    parseResult.assertErrors([
      error(diag.expectedExecutable, 0, 1),
      error(diag.expectedToken, 4, 1),
      error(diag.missingIdentifier, 6, 0),
      error(diag.expectedTypeName, 6, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: bar
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: <empty> <synthetic>
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_partial_typeArg2_34850() {
    var parseResult = parseStringWithErrors(r'''
foo <bar<
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 1),
      error(diag.missingIdentifier, 10, 0),
      error(diag.expectedTypeName, 10, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: foo
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: bar
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: <empty> <synthetic>
                  rightBracket: > <synthetic>
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }
}
