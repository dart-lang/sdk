// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InstanceCreationTest extends ParserDiagnosticsTest {
  void test_instance_creation_expression_const_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => const;
//          ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '('.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: const
            constructorName: ConstructorName
              type: NamedType
                name: <empty> <synthetic>
            argumentList: ArgumentList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_const_leftParen_named_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => const A.b(;
//               ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: const
            constructorName: ConstructorName
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: A
                  period: .
                name: b
            argumentList: ArgumentList
              leftParenthesis: (
              arguments
                SimpleIdentifier
                  token: <empty> <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_const_leftParen_unnamed_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => const A(;
//             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: const
            constructorName: ConstructorName
              type: NamedType
                name: A
            argumentList: ArgumentList
              leftParenthesis: (
              arguments
                SimpleIdentifier
                  token: <empty> <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_const_name_dot_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => const A.;
//             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '('.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: const
            constructorName: ConstructorName
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: A
                  period: .
                name: <empty> <synthetic>
            argumentList: ArgumentList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_const_name_named_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => const A.b;
//             ^
// [diag.expectedToken] Expected to find '('.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: const
            constructorName: ConstructorName
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: A
                  period: .
                name: b
            argumentList: ArgumentList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_const_name_unnamed_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => const A;
//           ^
// [diag.expectedToken] Expected to find '('.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: const
            constructorName: ConstructorName
              type: NamedType
                name: A
            argumentList: ArgumentList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_new_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => new;
//        ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '('.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: new
            constructorName: ConstructorName
              type: NamedType
                name: <empty> <synthetic>
            argumentList: ArgumentList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_new_leftParen_named_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => new A.b(;
//             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: new
            constructorName: ConstructorName
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: A
                  period: .
                name: b
            argumentList: ArgumentList
              leftParenthesis: (
              arguments
                SimpleIdentifier
                  token: <empty> <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_new_leftParen_unnamed_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => new A(;
//           ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: new
            constructorName: ConstructorName
              type: NamedType
                name: A
            argumentList: ArgumentList
              leftParenthesis: (
              arguments
                SimpleIdentifier
                  token: <empty> <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_new_name_dot_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => new A.;
//           ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '('.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: new
            constructorName: ConstructorName
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: A
                  period: .
                name: <empty> <synthetic>
            argumentList: ArgumentList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_new_name_named_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => new A.b;
//           ^
// [diag.expectedToken] Expected to find '('.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: new
            constructorName: ConstructorName
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: A
                  period: .
                name: b
            argumentList: ArgumentList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }

  void test_instance_creation_expression_new_name_unnamed_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => new A;
//         ^
// [diag.expectedToken] Expected to find '('.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            keyword: new
            constructorName: ConstructorName
              type: NamedType
                name: A
            argumentList: ArgumentList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
          semicolon: ;
''');
  }
}
