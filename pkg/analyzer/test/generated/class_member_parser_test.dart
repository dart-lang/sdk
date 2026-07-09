// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  $content
}
''');
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
''');
  }

  void test_parse_member_called_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void late() {
    new C().late();
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() async {
    await x;
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() {
    await x;
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() {
    return await x + await y;
//         ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
//                   ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() {
    await returnsFuture();
//  ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() {
    if (await returnsFuture()) {
//      ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
    } else if (!await returnsFuture()) {}
//              ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() {
    print(await returnsFuture());
//        ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() {
    xor(await returnsFuture(), await returnsFuture(), await returnsFuture());
//      ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
//                             ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
//                                                    ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() {
    await returnsFuture() ^ await returnsFuture();
//  ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
//                          ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m() {
    print(await returnsFuture() ^ await returnsFuture());
//        ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
//                                ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  Foo(dynamic a) : x = a is int ? {} : [] { /*body */
//^^^
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Foo(dynamic a, dynamic b) : x = a is int, y = b is int?;
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                          ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Foo(dynamic a, dynamic b) : x = a is int?, y = b is int;
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                          ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Foo(dynamic a, dynamic b) : x = a is int, y = b is int? {}
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                          ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
//                                                    ^
// [diag.expectedToken] Expected to find ';'.
//                                                      ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Foo(dynamic a, dynamic b) : x = a is int?, y = b is int {}
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                          ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
//                                                  ^^^
// [diag.expectedToken] Expected to find ';'.
//                                                      ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Foo(dynamic a, dynamic b) : x = a as int, y = b as int?;
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                          ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Foo(dynamic a, dynamic b) : x = a as int?, y = b as int;
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                          ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Foo(dynamic a, dynamic b) : x = a as int, y = b as int? {}
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                          ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
//                                                    ^
// [diag.expectedToken] Expected to find ';'.
//                                                      ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Foo(dynamic a, dynamic b) : x = a as int?, y = b as int {}
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                          ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
//                                                  ^^^
// [diag.expectedToken] Expected to find ';'.
//                                                      ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  /// Doc
  C();
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C(_, _$, this.__) : _a = _ + _$ {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  covariant T f;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  List<List<N>> _allComponents = new List<List<N>>.empty();
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  Function(int) Function(String) v;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  Function(int, String) v;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  p.A f;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var get;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var operator;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var operator = (5);
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var set;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var for;
//    ^^^
// [diag.expectedIdentifierButGotKeyword] 'for' can't be used as an identifier because it's a keyword.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var ;
//    ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var "";
//    ^^
// [diag.missingIdentifier] Expected an identifier.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  static A f;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  covariant late final int f = 0;
//^^^^^^^^^
// [diag.finalAndCovariantLateWithInitializer] Members marked 'late' with an initializer can't be declared to be both 'final' and 'covariant'.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int Function(int) get g {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void get g {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  external m();
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  external int m(int a);
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m<T>() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  m<T>(T p) => null;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  T m<T>() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  T m<T extends num>() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  Map<int, T> m<T>() => null;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  static T m<T>() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void m<T>() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  get() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  static int get C => 0;
//               ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int get() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void get() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  Function<A>(core.List<core.int> x) m() => null;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void Function<A>(core.List<core.int> x) m() => null;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  operator() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int operator() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void operator() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int Function(String) m() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  p.A m() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  set() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  static void set C(_) {}
//                ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int set() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void set() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  static void m() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin C {
  static void m() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f(int x, int y) {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int Function() operator +(int Function() f) {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  bool operator >>>(other) => false;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  foo(int value) {
    x >>>= value;
  }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int operator [](int i) {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int operator []=(int i) {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  bool operator <(other) => false;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  const factory C() = prefix.B.foo;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  factory C() => throw 0;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  factory C() = B;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C(x, y) : _x = x, assert(x < y), _y = y;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  external const factory C();
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  factory C.foo() => throw 0;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C(x, y) : _x = x, this._y = y;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C{ C() : super() * (); }
//             ^^^^^^^^^^^^
// [diag.invalidInitializer] Not a valid initializer.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C.foo();
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class{const():super.{n
//   ^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '('.
//                   ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 23][length 1] Expected to find '}'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A { operator/() : super(); }
//        ^^^^^^^^
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : super()[];
//      ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
//              ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : this()[];
//      ^^^^
// [diag.invalidThisInInitializer] Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())
//             ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C();
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : a = (b) {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : this.a = b;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : a = b;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  abstract int i;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  abstract external int i;
//^^^^^^^^
// [diag.abstractExternalField] Fields can't be declared both 'abstract' and 'external'.
}
''');
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  externalKeyword: external
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

  void test_parseField_abstract_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  abstract late int? i;
//^^^^^^^^
// [diag.abstractLateField] Abstract fields cannot be late.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  abstract late final int? i;
//^^^^^^^^
// [diag.abstractLateField] Abstract fields cannot be late.
}
''');
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

  void test_parseField_const_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  const late T f = 0;
//      ^^^^
// [diag.conflictingModifiers] Members can't be declared to be both 'late' and 'const'.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  external int i;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  external abstract int i;
//         ^^^^^^^^
// [diag.abstractExternalField] Fields can't be declared both 'abstract' and 'external'.
}
''');
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  externalKeyword: external
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

  void test_parseField_external_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  external late int? i;
//^^^^^^^^
// [diag.externalLateField] External fields cannot be late.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  external late final int? i;
//^^^^^^^^
// [diag.externalLateField] External fields cannot be late.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  external static int? i;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  final late T f;
//      ^^^^
// [diag.modifierOutOfOrder] The modifier 'late' should be before the modifier 'final'.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  late T f;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  late const T f = 0;
//     ^^^^^
// [diag.conflictingModifiers] Members can't be declared to be both 'const' and 'late'.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  late final T f;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  late var f;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int i;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int i;
}
''');
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

  void test_parseField_static_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  static abstract int? i;
}
''');
    var node = parseResult.findNode.singleClassMember;
    assertParsedNodeText(node, r'''
FieldDeclaration
  staticKeyword: static
  abstractKeyword: abstract
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

  void test_parseField_var_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var late f;
//    ^^^^
// [diag.modifierOutOfOrder] The modifier 'late' should be before the modifier 'var'.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  /// Doc
  T get a;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  /// Doc
  static T get a => 42;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  /// Doc
  static T a = 1, b, c = 3;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  /// Doc
  static var a = 1, b, c = 3;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  /// Doc
  T operator +(A a);
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  /// Doc
  T set a(var x);
//        ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  /// Doc
  static T set a(var x) {}
//               ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int f(
    /// Doc
    int x,
  ) {}
}
''');
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
