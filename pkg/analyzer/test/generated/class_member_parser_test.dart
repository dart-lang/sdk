// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Tests which exercise the parser using a class member.
@reflectiveTest
class ClassMemberParserTest extends ParserDiagnosticsTest {
  void parseClassMember_constructor_initializers_49132_helper(
    String content, {
    bool xIsNullable = false,
    bool yIsNullable = false,
    bool isVariation = false,
  }) {
    var parseResult = parseStringWithErrors(r'''
class C {
  $content
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
''');
  }

  void test_parse_member_called_late() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void late() {
    new C().late();
  }
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
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: void
            name: late
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
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
                        token: late
                      argumentList: ArgumentList
                        leftParenthesis: (
                        rightParenthesis: )
                    semicolon: ;
                rightBracket: }
        rightBracket: }
''');
  }

  void test_parseAwaitExpression_asStatement_inAsync() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() async {
    await x;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    keyword: async
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: AwaitExpression
            awaitKeyword: await
            expression: SimpleIdentifier
              token: x
          semicolon: ;
      rightBracket: }
''');
  }

  void test_parseAwaitExpression_asStatement_inSync() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() {
    await x;
  }
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
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
              name: await
            variables
              VariableDeclaration
                name: x
          semicolon: ;
      rightBracket: }
''');
  }

  void test_parseAwaitExpression_inSync() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() {
    return await x + await y;
  }
}
''');
    parseResult.assertErrors([
      error(diag.awaitInWrongContext, 29, 5),
      error(diag.awaitInWrongContext, 39, 5),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ReturnStatement
          returnKeyword: return
          expression: BinaryExpression
            leftOperand: AwaitExpression
              awaitKeyword: await
              expression: SimpleIdentifier
                token: x
            operator: +
            rightOperand: AwaitExpression
              awaitKeyword: await
              expression: SimpleIdentifier
                token: y
          semicolon: ;
      rightBracket: }
''');
  }

  void test_parseAwaitExpression_inSync_v1_49116() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() {
    await returnsFuture();
  }
}
''');
    parseResult.assertErrors([error(diag.awaitInWrongContext, 22, 5)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: AwaitExpression
            awaitKeyword: await
            expression: MethodInvocation
              methodName: SimpleIdentifier
                token: returnsFuture
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
          semicolon: ;
      rightBracket: }
''');
  }

  void test_parseAwaitExpression_inSync_v2_49116() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() {
    if (await returnsFuture()) {
    } else if (!await returnsFuture()) {}
  }
}
''');
    parseResult.assertErrors([
      error(diag.awaitInWrongContext, 26, 5),
      error(diag.awaitInWrongContext, 67, 5),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        IfStatement
          ifKeyword: if
          leftParenthesis: (
          expression: AwaitExpression
            awaitKeyword: await
            expression: MethodInvocation
              methodName: SimpleIdentifier
                token: returnsFuture
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
          rightParenthesis: )
          thenStatement: Block
            leftBracket: {
            rightBracket: }
          elseKeyword: else
          elseStatement: IfStatement
            ifKeyword: if
            leftParenthesis: (
            expression: PrefixExpression
              operator: !
              operand: AwaitExpression
                awaitKeyword: await
                expression: MethodInvocation
                  methodName: SimpleIdentifier
                    token: returnsFuture
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
            rightParenthesis: )
            thenStatement: Block
              leftBracket: {
              rightBracket: }
      rightBracket: }
''');
  }

  void test_parseAwaitExpression_inSync_v3_49116() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() {
    print(await returnsFuture());
  }
}
''');
    parseResult.assertErrors([error(diag.awaitInWrongContext, 28, 5)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: print
            argumentList: ArgumentList
              leftParenthesis: (
              arguments
                AwaitExpression
                  awaitKeyword: await
                  expression: MethodInvocation
                    methodName: SimpleIdentifier
                      token: returnsFuture
                    argumentList: ArgumentList
                      leftParenthesis: (
                      rightParenthesis: )
              rightParenthesis: )
          semicolon: ;
      rightBracket: }
''');
  }

  void test_parseAwaitExpression_inSync_v4_49116() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() {
    xor(await returnsFuture(), await returnsFuture(), await returnsFuture());
  }
}
''');
    parseResult.assertErrors([
      error(diag.awaitInWrongContext, 26, 5),
      error(diag.awaitInWrongContext, 49, 5),
      error(diag.awaitInWrongContext, 72, 5),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: xor
            argumentList: ArgumentList
              leftParenthesis: (
              arguments
                AwaitExpression
                  awaitKeyword: await
                  expression: MethodInvocation
                    methodName: SimpleIdentifier
                      token: returnsFuture
                    argumentList: ArgumentList
                      leftParenthesis: (
                      rightParenthesis: )
                AwaitExpression
                  awaitKeyword: await
                  expression: MethodInvocation
                    methodName: SimpleIdentifier
                      token: returnsFuture
                    argumentList: ArgumentList
                      leftParenthesis: (
                      rightParenthesis: )
                AwaitExpression
                  awaitKeyword: await
                  expression: MethodInvocation
                    methodName: SimpleIdentifier
                      token: returnsFuture
                    argumentList: ArgumentList
                      leftParenthesis: (
                      rightParenthesis: )
              rightParenthesis: )
          semicolon: ;
      rightBracket: }
''');
  }

  void test_parseAwaitExpression_inSync_v5_49116() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() {
    await returnsFuture() ^ await returnsFuture();
  }
}
''');
    parseResult.assertErrors([
      error(diag.awaitInWrongContext, 22, 5),
      error(diag.awaitInWrongContext, 46, 5),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: BinaryExpression
            leftOperand: AwaitExpression
              awaitKeyword: await
              expression: MethodInvocation
                methodName: SimpleIdentifier
                  token: returnsFuture
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
            operator: ^
            rightOperand: AwaitExpression
              awaitKeyword: await
              expression: MethodInvocation
                methodName: SimpleIdentifier
                  token: returnsFuture
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
          semicolon: ;
      rightBracket: }
''');
  }

  void test_parseAwaitExpression_inSync_v6_49116() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m() {
    print(await returnsFuture() ^ await returnsFuture());
  }
}
''');
    parseResult.assertErrors([
      error(diag.awaitInWrongContext, 28, 5),
      error(diag.awaitInWrongContext, 52, 5),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: print
            argumentList: ArgumentList
              leftParenthesis: (
              arguments
                BinaryExpression
                  leftOperand: AwaitExpression
                    awaitKeyword: await
                    expression: MethodInvocation
                      methodName: SimpleIdentifier
                        token: returnsFuture
                      argumentList: ArgumentList
                        leftParenthesis: (
                        rightParenthesis: )
                  operator: ^
                  rightOperand: AwaitExpression
                    awaitKeyword: await
                    expression: MethodInvocation
                      methodName: SimpleIdentifier
                        token: returnsFuture
                      argumentList: ArgumentList
                        leftParenthesis: (
                        rightParenthesis: )
              rightParenthesis: )
          semicolon: ;
      rightBracket: }
''');
  }

  void test_parseClassMember_constructor_initializers_conditional() {
    var parseResult = parseStringWithErrors(r'''
class C {
  Foo(dynamic a) : x = a is int ? {} : [] { /*body */
}
}
''');
    parseResult.assertErrors([error(diag.invalidConstructorName, 12, 3)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: Foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: dynamic
      name: a
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: x
      equals: =
      expression: ConditionalExpression
        condition: IsExpression
          expression: SimpleIdentifier
            token: a
          isOperator: is
          type: NamedType
            name: int
        question: ?
        thenExpression: SetOrMapLiteral
          leftBracket: {
          rightBracket: }
          isMap: false
        colon: :
        elseExpression: ListLiteral
          leftBracket: [
          rightBracket: ]
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_constructor_initializers_is_nullable_v1_49132() {
    var parseResult = parseStringWithErrors(r'''
Foo(dynamic a, dynamic b) : x = a is int, y = b is int?;
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 26, 1),
      error(diag.expectedExecutable, 26, 1),
      error(diag.missingConstFinalVarOrType, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IsExpression
              expression: SimpleIdentifier
                token: a
              isOperator: is
              type: NamedType
                name: int
          VariableDeclaration
            name: y
            equals: =
            initializer: IsExpression
              expression: SimpleIdentifier
                token: b
              isOperator: is
              type: NamedType
                name: int
                question: ?
      semicolon: ;
''');
  }

  void test_parseClassMember_constructor_initializers_is_nullable_v2_49132() {
    var parseResult = parseStringWithErrors(r'''
Foo(dynamic a, dynamic b) : x = a is int?, y = b is int;
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 26, 1),
      error(diag.expectedExecutable, 26, 1),
      error(diag.missingConstFinalVarOrType, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IsExpression
              expression: SimpleIdentifier
                token: a
              isOperator: is
              type: NamedType
                name: int
                question: ?
          VariableDeclaration
            name: y
            equals: =
            initializer: IsExpression
              expression: SimpleIdentifier
                token: b
              isOperator: is
              type: NamedType
                name: int
      semicolon: ;
''');
  }

  void test_parseClassMember_constructor_initializers_is_nullable_v3_49132() {
    var parseResult = parseStringWithErrors(r'''
Foo(dynamic a, dynamic b) : x = a is int, y = b is int? {}
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 26, 1),
      error(diag.expectedExecutable, 26, 1),
      error(diag.missingConstFinalVarOrType, 28, 1),
      error(diag.expectedToken, 54, 1),
      error(diag.expectedExecutable, 56, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IsExpression
              expression: SimpleIdentifier
                token: a
              isOperator: is
              type: NamedType
                name: int
          VariableDeclaration
            name: y
            equals: =
            initializer: IsExpression
              expression: SimpleIdentifier
                token: b
              isOperator: is
              type: NamedType
                name: int
                question: ?
      semicolon: ; <synthetic>
''');
  }

  void test_parseClassMember_constructor_initializers_is_nullable_v4_49132() {
    var parseResult = parseStringWithErrors(r'''
Foo(dynamic a, dynamic b) : x = a is int?, y = b is int {}
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 26, 1),
      error(diag.expectedExecutable, 26, 1),
      error(diag.missingConstFinalVarOrType, 28, 1),
      error(diag.expectedToken, 52, 3),
      error(diag.expectedExecutable, 56, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IsExpression
              expression: SimpleIdentifier
                token: a
              isOperator: is
              type: NamedType
                name: int
                question: ?
          VariableDeclaration
            name: y
            equals: =
            initializer: IsExpression
              expression: SimpleIdentifier
                token: b
              isOperator: is
              type: NamedType
                name: int
      semicolon: ; <synthetic>
''');
  }

  void test_parseClassMember_constructor_initializers_nullable_cast_v1_49132() {
    var parseResult = parseStringWithErrors(r'''
Foo(dynamic a, dynamic b) : x = a as int, y = b as int?;
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 26, 1),
      error(diag.expectedExecutable, 26, 1),
      error(diag.missingConstFinalVarOrType, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: AsExpression
              expression: SimpleIdentifier
                token: a
              asOperator: as
              type: NamedType
                name: int
          VariableDeclaration
            name: y
            equals: =
            initializer: AsExpression
              expression: SimpleIdentifier
                token: b
              asOperator: as
              type: NamedType
                name: int
                question: ?
      semicolon: ;
''');
  }

  void test_parseClassMember_constructor_initializers_nullable_cast_v2_49132() {
    var parseResult = parseStringWithErrors(r'''
Foo(dynamic a, dynamic b) : x = a as int?, y = b as int;
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 26, 1),
      error(diag.expectedExecutable, 26, 1),
      error(diag.missingConstFinalVarOrType, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: AsExpression
              expression: SimpleIdentifier
                token: a
              asOperator: as
              type: NamedType
                name: int
                question: ?
          VariableDeclaration
            name: y
            equals: =
            initializer: AsExpression
              expression: SimpleIdentifier
                token: b
              asOperator: as
              type: NamedType
                name: int
      semicolon: ;
''');
  }

  void test_parseClassMember_constructor_initializers_nullable_cast_v3_49132() {
    var parseResult = parseStringWithErrors(r'''
Foo(dynamic a, dynamic b) : x = a as int, y = b as int? {}
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 26, 1),
      error(diag.expectedExecutable, 26, 1),
      error(diag.missingConstFinalVarOrType, 28, 1),
      error(diag.expectedToken, 54, 1),
      error(diag.expectedExecutable, 56, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: AsExpression
              expression: SimpleIdentifier
                token: a
              asOperator: as
              type: NamedType
                name: int
          VariableDeclaration
            name: y
            equals: =
            initializer: AsExpression
              expression: SimpleIdentifier
                token: b
              asOperator: as
              type: NamedType
                name: int
                question: ?
      semicolon: ; <synthetic>
''');
  }

  void test_parseClassMember_constructor_initializers_nullable_cast_v4_49132() {
    var parseResult = parseStringWithErrors(r'''
Foo(dynamic a, dynamic b) : x = a as int?, y = b as int {}
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 26, 1),
      error(diag.expectedExecutable, 26, 1),
      error(diag.missingConstFinalVarOrType, 28, 1),
      error(diag.expectedToken, 52, 3),
      error(diag.expectedExecutable, 56, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: dynamic
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: AsExpression
              expression: SimpleIdentifier
                token: a
              asOperator: as
              type: NamedType
                name: int
                question: ?
          VariableDeclaration
            name: y
            equals: =
            initializer: AsExpression
              expression: SimpleIdentifier
                token: b
              asOperator: as
              type: NamedType
                name: int
      semicolon: ; <synthetic>
''');
  }

  void test_parseClassMember_constructor_withDocComment() {
    var parseResult = parseStringWithErrors(r'''
class C {
  /// Doc
  C();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  documentationComment: Comment
    tokens
      /// Doc
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseClassMember_constructor_withInitializers() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C(_, _$, this.__) : _a = _ + _$ {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: _
    parameter: RegularFormalParameter
      name: _$
    parameter: FieldFormalParameter
      thisKeyword: this
      period: .
      name: __
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: _a
      equals: =
      expression: BinaryExpression
        leftOperand: SimpleIdentifier
          token: _
        operator: +
        rightOperand: SimpleIdentifier
          token: _$
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_field_covariant() {
    var parseResult = parseStringWithErrors(r'''
class C {
  covariant T f;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  covariantKeyword: covariant
  fields: VariableDeclarationList
    type: NamedType
      name: T
    variables
      VariableDeclaration
        name: f
  semicolon: ;
''');
  }

  void test_parseClassMember_field_generic() {
    var parseResult = parseStringWithErrors(r'''
class C {
  List<List<N>> _allComponents = new List<List<N>>.empty();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    type: NamedType
      name: List
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: List
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: N
              rightBracket: >
        rightBracket: >
    variables
      VariableDeclaration
        name: _allComponents
        equals: =
        initializer: InstanceCreationExpression
          keyword: new
          constructorName: ConstructorName
            type: NamedType
              name: List
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: List
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: N
                      rightBracket: >
                rightBracket: >
            period: .
            name: SimpleIdentifier
              token: empty
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
  semicolon: ;
''');
  }

  void test_parseClassMember_field_gftType_gftReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  Function(int) Function(String) v;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
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
            name: String
        rightParenthesis: )
    variables
      VariableDeclaration
        name: v
  semicolon: ;
''');
  }

  void test_parseClassMember_field_gftType_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  Function(int, String) v;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    type: GenericFunctionType
      functionKeyword: Function
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: RegularFormalParameter
          type: NamedType
            name: int
        parameter: RegularFormalParameter
          type: NamedType
            name: String
        rightParenthesis: )
    variables
      VariableDeclaration
        name: v
  semicolon: ;
''');
  }

  void test_parseClassMember_field_instance_prefixedType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  p.A f;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
      name: A
    variables
      VariableDeclaration
        name: f
  semicolon: ;
''');
  }

  void test_parseClassMember_field_namedGet() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var get;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: get
  semicolon: ;
''');
  }

  void test_parseClassMember_field_namedOperator() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var operator;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: operator
  semicolon: ;
''');
  }

  void test_parseClassMember_field_namedOperator_withAssignment() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var operator = (5);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: operator
        equals: =
        initializer: ParenthesizedExpression
          leftParenthesis: (
          expression: IntegerLiteral
            literal: 5
          rightParenthesis: )
  semicolon: ;
''');
  }

  void test_parseClassMember_field_namedSet() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var set;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: set
  semicolon: ;
''');
  }

  void test_parseClassMember_field_nameKeyword() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var for;
}
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 16, 3),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: for
  semicolon: ;
''');
  }

  void test_parseClassMember_field_nameMissing() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var ;
}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 1)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: <empty> <synthetic>
  semicolon: ;
''');
  }

  void test_parseClassMember_field_nameMissing2() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var "";
}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 2)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: <empty> <synthetic>
  semicolon: ;
''');
  }

  void test_parseClassMember_field_static() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static A f;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  staticKeyword: static
  fields: VariableDeclarationList
    type: NamedType
      name: A
    variables
      VariableDeclaration
        name: f
  semicolon: ;
''');
  }

  void test_parseClassMember_finalAndCovariantLateWithInitializer() {
    var parseResult = parseStringWithErrors(r'''
class C {
  covariant late final int f = 0;
}
''');
    parseResult.assertErrors([
      error(diag.finalAndCovariantLateWithInitializer, 12, 9),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: final
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: f
        equals: =
        initializer: IntegerLiteral
          literal: 0
  semicolon: ;
''');
  }

  void test_parseClassMember_getter_functionType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int Function(int) get g {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
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
  propertyKeyword: get
  name: g
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_getter_void() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void get g {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  propertyKeyword: get
  name: g
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_external() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external m();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  externalKeyword: external
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseClassMember_method_external_withTypeAndArgs() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external int m(int a);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  externalKeyword: external
  returnType: NamedType
    name: int
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseClassMember_method_generic_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m<T>() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_generic_parameterType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  m<T>(T p) => null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: m
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
      name: p
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
    semicolon: ;
''');
  }

  void test_parseClassMember_method_generic_returnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  T m<T>() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: T
  name: m
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_generic_returnType_bound() {
    var parseResult = parseStringWithErrors(r'''
class C {
  T m<T extends num>() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: T
  name: m
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        extendsKeyword: extends
        bound: NamedType
          name: num
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_generic_returnType_complex() {
    var parseResult = parseStringWithErrors(r'''
class C {
  Map<int, T> m<T>() => null;
}
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.singleClassDeclaration.body as BlockClassBody)
            .members
            .first;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: Map
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
        NamedType
          name: T
      rightBracket: >
  name: m
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
    semicolon: ;
''');
  }

  void test_parseClassMember_method_generic_returnType_static() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static T m<T>() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: T
  name: m
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_generic_void() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void m<T>() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: m
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_get_noType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  get() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: get
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_get_static_namedAsClass() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static int get C => 0;
}
''');
    parseResult.assertErrors([error(diag.memberWithClassName, 27, 1)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: C
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
    semicolon: ;
''');
  }

  void test_parseClassMember_method_get_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int get() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: int
  name: get
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_get_void() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void get() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: get
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_gftReturnType_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  Function<A>(core.List<core.int> x) m() => null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: GenericFunctionType
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
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
    semicolon: ;
''');
  }

  void test_parseClassMember_method_gftReturnType_voidReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void Function<A>(core.List<core.int> x) m() => null;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
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
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
    semicolon: ;
''');
  }

  void test_parseClassMember_method_operator_noType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  operator() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: operator
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_operator_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: int
  name: operator
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_operator_void() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void operator() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: operator
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_returnType_functionType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int Function(String) m() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: GenericFunctionType
    returnType: NamedType
      name: int
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: String
      rightParenthesis: )
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_returnType_parameterized() {
    var parseResult = parseStringWithErrors(r'''
class C {
  p.A m() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
    name: A
  name: m
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_set_noType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  set() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  name: set
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_set_static_namedAsClass() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static void set C(_) {}
}
''');
    parseResult.assertErrors([error(diag.memberWithClassName, 28, 1)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: void
  propertyKeyword: set
  name: C
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: _
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_set_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int set() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: int
  name: set
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_set_void() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void set() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: set
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_method_static_class() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static void m() {}
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
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            modifierKeyword: static
            returnType: NamedType
              name: void
            name: m
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

  void test_parseClassMember_method_static_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin C {
  static void m() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            modifierKeyword: static
            returnType: NamedType
              name: void
            name: m
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

  void test_parseClassMember_method_trailing_commas() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f(int x, int y) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: f
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: x
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: y
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_operator_functionType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int Function() operator +(int Function() f) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: GenericFunctionType
    returnType: NamedType
      name: int
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  operatorKeyword: operator
  name: +
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: GenericFunctionType
        returnType: NamedType
          name: int
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      name: f
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_operator_gtgtgt() {
    var parseResult = parseStringWithErrors(r'''
class C {
  bool operator >>>(other) => false;
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
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: bool
            operatorKeyword: operator
            name: >>>
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: other
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BooleanLiteral
                literal: false
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseClassMember_operator_gtgtgteq() {
    var parseResult = parseStringWithErrors(r'''
class C {
  foo(int value) {
    x >>>= value;
  }
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
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            name: foo
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: value
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                statements
                  ExpressionStatement
                    expression: AssignmentExpression
                      leftHandSide: SimpleIdentifier
                        token: x
                      operator: >>>=
                      rightHandSide: SimpleIdentifier
                        token: value
                    semicolon: ;
                rightBracket: }
        rightBracket: }
''');
  }

  void test_parseClassMember_operator_index() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator [](int i) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: int
  operatorKeyword: operator
  name: []
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: i
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_operator_indexAssign() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator []=(int i) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: int
  operatorKeyword: operator
  name: []=
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: i
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseClassMember_operator_lessThan() {
    var parseResult = parseStringWithErrors(r'''
class C {
  bool operator <(other) => false;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: bool
  operatorKeyword: operator
  name: <
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: other
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: BooleanLiteral
      literal: false
    semicolon: ;
''');
  }

  void test_parseClassMember_redirectingFactory_const() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const factory C() = prefix.B.foo;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
      name: B
    period: .
    name: SimpleIdentifier
      token: foo
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseClassMember_redirectingFactory_expressionBody() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory C() => throw 0;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: ThrowExpression
      throwKeyword: throw
      expression: IntegerLiteral
        literal: 0
    semicolon: ;
''');
  }

  void test_parseClassMember_redirectingFactory_nonConst() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory C() = B;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: B
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseConstructor_assert() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C(x, y) : _x = x, assert(x < y), _y = y;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: x
    parameter: RegularFormalParameter
      name: y
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: _x
      equals: =
      expression: SimpleIdentifier
        token: x
    AssertInitializer
      assertKeyword: assert
      leftParenthesis: (
      condition: BinaryExpression
        leftOperand: SimpleIdentifier
          token: x
        operator: <
        rightOperand: SimpleIdentifier
          token: y
      rightParenthesis: )
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: _y
      equals: =
      expression: SimpleIdentifier
        token: y
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseConstructor_factory_const_external() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external const factory C();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  externalKeyword: external
  constKeyword: const
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseConstructor_factory_named() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory C.foo() => throw 0;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  period: .
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: ThrowExpression
      throwKeyword: throw
      expression: IntegerLiteral
        literal: 0
    semicolon: ;
''');
  }

  void test_parseConstructor_initializers_field() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C(x, y) : _x = x, this._y = y;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: x
    parameter: RegularFormalParameter
      name: y
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: _x
      equals: =
      expression: SimpleIdentifier
        token: x
    ConstructorFieldInitializer
      thisKeyword: this
      period: .
      fieldName: SimpleIdentifier
        token: _y
      equals: =
      expression: SimpleIdentifier
        token: y
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseConstructor_invalidInitializer() {
    var parseResult = parseStringWithErrors(r'''
class C{ C() : super() * (); }
''');
    parseResult.assertErrors([error(diag.invalidInitializer, 15, 12)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseConstructor_named() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C.foo();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  period: .
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseConstructor_nullSuperArgList_openBrace_37735() {
    var parseResult = parseStringWithErrors(r'''
class{const():super.{n
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 1),
      error(diag.missingIdentifier, 11, 1),
      error(diag.invalidConstructorName, 11, 1),
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 20, 1),
      error(diag.expectedToken, 21, 1),
      error(diag.expectedToken, 23, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            constKeyword: const
            typeName: SimpleIdentifier
              token: <empty> <synthetic>
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                statements
                  ExpressionStatement
                    expression: SimpleIdentifier
                      token: n
                    semicolon: ; <synthetic>
                rightBracket: } <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_parseConstructor_operator_name() {
    var parseResult = parseStringWithErrors(r'''
class A { operator/() : super(); }
''');
    parseResult.assertErrors([error(diag.invalidConstructorName, 10, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: /
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseConstructor_superIndexed() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : super()[];
}
''');
    parseResult.assertErrors([
      error(diag.invalidSuperInInitializer, 18, 5),
      error(diag.missingIdentifier, 26, 1),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    SuperConstructorInvocation
      superKeyword: super
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseConstructor_thisIndexed() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : this()[];
}
''');
    parseResult.assertErrors([
      error(diag.invalidThisInInitializer, 18, 4),
      error(diag.missingIdentifier, 25, 1),
    ]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    RedirectingConstructorInvocation
      thisKeyword: this
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseConstructor_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseConstructor_with_pseudo_function_literal() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : a = (b) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: a
      equals: =
      expression: ParenthesizedExpression
        leftParenthesis: (
        expression: SimpleIdentifier
          token: b
        rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseConstructorFieldInitializer_qualified() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : this.a = b;
}
''');
    parseResult.assertNoErrors();
    var node =
        parseResult.findNode.singleConstructorDeclaration.initializers.first;
    assertParsedNodeText(node, r'''
ConstructorFieldInitializer
  thisKeyword: this
  period: .
  fieldName: SimpleIdentifier
    token: a
  equals: =
  expression: SimpleIdentifier
    token: b
''');
  }

  void test_parseConstructorFieldInitializer_unqualified() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : a = b;
}
''');
    parseResult.assertNoErrors();
    var node =
        parseResult.findNode.singleConstructorDeclaration.initializers.first;
    assertParsedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: a
  equals: =
  expression: SimpleIdentifier
    token: b
''');
  }

  void test_parseField_abstract() {
    var parseResult = parseStringWithErrors(r'''
class C {
  abstract int i;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  abstractKeyword: abstract
  fields: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_abstract_external() {
    var parseResult = parseStringWithErrors(r'''
class C {
  abstract external int i;
}
''');
    parseResult.assertErrors([error(diag.abstractExternalField, 12, 8)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  abstractKeyword: abstract
  externalKeyword: external
  fields: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_abstract_late() {
    var parseResult = parseStringWithErrors(r'''
class C {
  abstract late int? i;
}
''');
    parseResult.assertErrors([error(diag.abstractLateField, 12, 8)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  abstractKeyword: abstract
  fields: VariableDeclarationList
    lateKeyword: late
    type: NamedType
      name: int
      question: ?
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_abstract_late_final() {
    var parseResult = parseStringWithErrors(r'''
class C {
  abstract late final int? i;
}
''');
    parseResult.assertErrors([error(diag.abstractLateField, 12, 8)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  abstractKeyword: abstract
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: final
    type: NamedType
      name: int
      question: ?
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_abstract_static() {
    var parseResult = parseStringWithErrors(r'''
class C {
  abstract static int? i;
}
''');
    parseResult.assertErrors([error(diag.abstractStaticField, 12, 8)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  abstractKeyword: abstract
  staticKeyword: static
  fields: VariableDeclarationList
    type: NamedType
      name: int
      question: ?
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_const_late() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const late T f = 0;
}
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 18, 4)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: const
    type: NamedType
      name: T
    variables
      VariableDeclaration
        name: f
        equals: =
        initializer: IntegerLiteral
          literal: 0
  semicolon: ;
''');
  }

  void test_parseField_external() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external int i;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  externalKeyword: external
  fields: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_external_abstract() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external abstract int i;
}
''');
    parseResult.assertErrors([error(diag.abstractExternalField, 21, 8)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  abstractKeyword: abstract
  externalKeyword: external
  fields: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_external_late() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external late int? i;
}
''');
    parseResult.assertErrors([error(diag.externalLateField, 12, 8)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  externalKeyword: external
  fields: VariableDeclarationList
    lateKeyword: late
    type: NamedType
      name: int
      question: ?
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_external_late_final() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external late final int? i;
}
''');
    parseResult.assertErrors([error(diag.externalLateField, 12, 8)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  externalKeyword: external
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: final
    type: NamedType
      name: int
      question: ?
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_external_static() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external static int? i;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  externalKeyword: external
  staticKeyword: static
  fields: VariableDeclarationList
    type: NamedType
      name: int
      question: ?
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_final_late() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final late T f;
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 18, 4)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: final
    type: NamedType
      name: T
    variables
      VariableDeclaration
        name: f
  semicolon: ;
''');
  }

  void test_parseField_late() {
    var parseResult = parseStringWithErrors(r'''
class C {
  late T f;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    type: NamedType
      name: T
    variables
      VariableDeclaration
        name: f
  semicolon: ;
''');
  }

  void test_parseField_late_const() {
    var parseResult = parseStringWithErrors(r'''
class C {
  late const T f = 0;
}
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 17, 5)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: const
    type: NamedType
      name: T
    variables
      VariableDeclaration
        name: f
        equals: =
        initializer: IntegerLiteral
          literal: 0
  semicolon: ;
''');
  }

  void test_parseField_late_final() {
    var parseResult = parseStringWithErrors(r'''
class C {
  late final T f;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: final
    type: NamedType
      name: T
    variables
      VariableDeclaration
        name: f
  semicolon: ;
''');
  }

  void test_parseField_late_var() {
    var parseResult = parseStringWithErrors(r'''
class C {
  late var f;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: var
    variables
      VariableDeclaration
        name: f
  semicolon: ;
''');
  }

  void test_parseField_non_abstract() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int i;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_non_external() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int i;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: i
  semicolon: ;
''');
  }

  void test_parseField_var_late() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var late f;
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 16, 4)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: var
    variables
      VariableDeclaration
        name: f
  semicolon: ;
''');
  }

  void test_parseGetter_nonStatic() {
    var parseResult = parseStringWithErrors(r'''
class C {
  /// Doc
  T get a;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  documentationComment: Comment
    tokens
      /// Doc
  returnType: NamedType
    name: T
  propertyKeyword: get
  name: a
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseGetter_static() {
    var parseResult = parseStringWithErrors(r'''
class C {
  /// Doc
  static T get a => 42;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  documentationComment: Comment
    tokens
      /// Doc
  modifierKeyword: static
  returnType: NamedType
    name: T
  propertyKeyword: get
  name: a
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 42
    semicolon: ;
''');
  }

  void test_parseInitializedIdentifierList_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  /// Doc
  static T a = 1, b, c = 3;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  documentationComment: Comment
    tokens
      /// Doc
  staticKeyword: static
  fields: VariableDeclarationList
    type: NamedType
      name: T
    variables
      VariableDeclaration
        name: a
        equals: =
        initializer: IntegerLiteral
          literal: 1
      VariableDeclaration
        name: b
      VariableDeclaration
        name: c
        equals: =
        initializer: IntegerLiteral
          literal: 3
  semicolon: ;
''');
  }

  void test_parseInitializedIdentifierList_var() {
    var parseResult = parseStringWithErrors(r'''
class C {
  /// Doc
  static var a = 1, b, c = 3;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  documentationComment: Comment
    tokens
      /// Doc
  staticKeyword: static
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: a
        equals: =
        initializer: IntegerLiteral
          literal: 1
      VariableDeclaration
        name: b
      VariableDeclaration
        name: c
        equals: =
        initializer: IntegerLiteral
          literal: 3
  semicolon: ;
''');
  }

  void test_parseOperator() {
    var parseResult = parseStringWithErrors(r'''
class C {
  /// Doc
  T operator +(A a);
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  documentationComment: Comment
    tokens
      /// Doc
  returnType: NamedType
    name: T
  operatorKeyword: operator
  name: +
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: A
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseSetter_nonStatic() {
    var parseResult = parseStringWithErrors(r'''
class C {
  /// Doc
  T set a(var x);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 30, 3)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  documentationComment: Comment
    tokens
      /// Doc
  returnType: NamedType
    name: T
  propertyKeyword: set
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      name: x
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_parseSetter_static() {
    var parseResult = parseStringWithErrors(r'''
class C {
  /// Doc
  static T set a(var x) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 37, 3)]);
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  documentationComment: Comment
    tokens
      /// Doc
  modifierKeyword: static
  returnType: NamedType
    name: T
  propertyKeyword: set
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      name: x
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_simpleFormalParameter_withDocComment() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int f(
    /// Doc
    int x,
  ) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: int
  name: f
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      documentationComment: Comment
        tokens
          /// Doc
      type: NamedType
        name: int
      name: x
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }
}
