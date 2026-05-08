// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(r'''
f() => const;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() => const A.b(;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 17, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() => const A(;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 15, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() => const A.;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedToken, 15, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() => const A.b;
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
f() => const A;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
f() => new;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 1),
      error(diag.expectedToken, 10, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() => new A.b(;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 15, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() => new A(;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 13, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() => new A.;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 1),
      error(diag.expectedToken, 13, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() => new A.b;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
f() => new A;
''');
    parseResult.assertErrors([error(diag.expectedToken, 11, 1)]);
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
