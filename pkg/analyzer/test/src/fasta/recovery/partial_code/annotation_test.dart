// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AnnotationTest extends ParserDiagnosticsTest {
  void test_annotation_classMember_ampersand_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ @annotation var f; }
//          ^
// [diag.missingIdentifier] Expected an identifier.
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
          FieldDeclaration
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: annotation
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ }
//          ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassMember] Expected a class member.
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ var f; }
//          ^^^
// [diag.missingIdentifier] Expected an identifier.
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
          FieldDeclaration
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ const f = 0; }
//          ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
          FieldDeclaration
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ final f = 0; }
//          ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
          FieldDeclaration
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ int get a => 0; }
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: int
            propertyKeyword: get
            name: a
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ int a(b) => 0; }
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ void a(b) {} }
//          ^^^^
// [diag.missingIdentifier] Expected an identifier.
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
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

  void test_annotation_classMember_ampersand_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @ set a(b) {} }
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
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

  void test_annotation_classMember_leftParen_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( @annotation var f; }
//            ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
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
          FieldDeclaration
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: a
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    SimpleIdentifier
                      token: <empty> <synthetic>
                  rightParenthesis: ) <synthetic>
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: annotation
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( }
//            ^
// [diag.expectedClassMember] Expected a class member.
// [diag.expectedToken] Expected to find ')'.
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( var f; }
//            ^^^
// [diag.missingIdentifier] Expected an identifier.
//            ^
// [diag.expectedToken] Expected to find ')'.
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
          FieldDeclaration
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: a
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    SimpleIdentifier
                      token: <empty> <synthetic>
                  rightParenthesis: ) <synthetic>
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( const f = 0; }
//            ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                  ^
// [diag.expectedToken] Expected to find '('.
//                       ^
// [diag.expectedClassMember] Expected a class member.
// [diag.expectedToken] Expected to find ')'.
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( final f = 0; }
//            ^^^^^
// [diag.missingIdentifier] Expected an identifier.
//            ^
// [diag.expectedToken] Expected to find ')'.
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
          FieldDeclaration
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: a
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    SimpleIdentifier
                      token: <empty> <synthetic>
                  rightParenthesis: ) <synthetic>
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( int get a => 0; }
//                ^^^
// [diag.expectedToken] Expected to find ','.
//                    ^
// [diag.expectedToken] Expected to find ','.
//                      ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
//                      ^
// [diag.expectedToken] Expected to find ')'.
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: a
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    SimpleIdentifier
                      token: int
                    SimpleIdentifier
                      token: get
                    SimpleIdentifier
                      token: a
                  rightParenthesis: ) <synthetic>
            name: <empty> <synthetic>
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( int a(b) => 0; }
//                ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                         ^
// [diag.expectedClassMember] Expected a class member.
// [diag.expectedToken] Expected to find ')'.
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( void a(b) {} }
//                 ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                         ^
// [diag.expectedClassMember] Expected a class member.
// [diag.expectedToken] Expected to find ')'.
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { @a( set a(b) {} }
//                ^
// [diag.expectedToken] Expected to find ','.
// [diag.namedFunctionExpression] Function expressions can't be named.
//                        ^
// [diag.expectedClassMember] Expected a class member.
// [diag.expectedToken] Expected to find ')'.
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
        rightBracket: }
''');
  }

  void test_annotation_local_ampersand_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ assert (true); }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ {} }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ break; }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ continue; }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ do {} while (true); }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ for (var x in y) {} }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: x
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: y
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ if (true) {} }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BooleanLiteral
                  literal: true
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ l: {} }
//       ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: l
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ int f() {} }
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: int
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

  void test_annotation_local_ampersand_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ void f() {} }
//      ^^^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  returnType: NamedType
                    name: void
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

  void test_annotation_local_ampersand_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ var x; }
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  keyword: var
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ return; }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ switch (x) {} }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ try {} finally {} }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
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

  void test_annotation_local_ampersand_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @ while (true) {} }
//    ^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( assert (true); }
//                     ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          FunctionExpressionInvocation
                            function: SimpleIdentifier
                              token: assert
                            argumentList: ArgumentList
                              leftParenthesis: (
                              arguments
                                BooleanLiteral
                                  literal: true
                              rightParenthesis: )
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( {} }
//         ^
// [diag.expectedToken] Expected to find ';'.
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SetOrMapLiteral
                            leftBracket: {
                            rightBracket: }
                            isMap: false
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( break; }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( continue; }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( do {} while (true); }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( for (var x in y) {} }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: x
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: y
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( if (true) {} }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BooleanLiteral
                  literal: true
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( l: {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          NamedArgument
                            name: l
                            colon: :
                            argumentExpression: SetOrMapLiteral
                              leftBracket: {
                              rightBracket: }
                              isMap: false
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( int f() {} }
//            ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          FunctionExpression
                            parameters: FormalParameterList
                              leftParenthesis: (
                              rightParenthesis: )
                            body: BlockFunctionBody
                              block: Block
                                leftBracket: {
                                rightBracket: }
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( void f() {} }
//             ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          FunctionExpression
                            parameters: FormalParameterList
                              leftParenthesis: (
                              rightParenthesis: )
                            body: BlockFunctionBody
                              block: Block
                                leftBracket: {
                                rightBracket: }
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( var x; }
//        ^^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  keyword: var
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( return; }
//        ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//              ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( switch (x) {} }
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SwitchExpression
                            switchKeyword: switch
                            leftParenthesis: (
                            expression: SimpleIdentifier
                              token: x
                            rightParenthesis: )
                            leftBracket: {
                            rightBracket: }
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( try {} finally {} }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
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

  void test_annotation_local_leftParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { @a( while (true) {} }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ class A {}
//^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ const a = 0;
//^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_annotation_topLevel_ampersand_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ enum E { v }
//^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@
// [diag.missingIdentifier][column 2][length 0] Expected an identifier.
// [diag.expectedExecutable][column 2][length 0] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_ampersand_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ final a = 0;
//^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_annotation_topLevel_ampersand_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ int f() {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: int
      name: f
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

  void test_annotation_topLevel_ampersand_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ void f() {}
//^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      returnType: NamedType
        name: void
      name: f
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

  void test_annotation_topLevel_ampersand_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ int get a => 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: int
      propertyKeyword: get
      name: a
      functionExpression: FunctionExpression
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
''');
  }

  void test_annotation_topLevel_ampersand_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ mixin M {}
//      ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: mixin
      name: M
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ set a(b) {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ typedef A = B Function(C, D);
//        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
//            ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: typedef
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: A
            equals: =
            initializer: SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
    FunctionDeclaration
      name: Function
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: C
          parameter: RegularFormalParameter
            name: D
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_annotation_topLevel_ampersand_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@ var a;
//^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_annotation_topLevel_leftParen_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( class A {}
//  ^^^^^
// [diag.expectedIdentifierButGotKeyword] 'class' can't be used as an identifier because it's a keyword.
//        ^
// [diag.expectedToken] Expected to find ','.
//          ^
// [diag.expectedToken] Expected to find ','.
//            ^
// [diag.expectedExecutable][column 15][length 0] Expected a method, getter, setter or operator declaration.
// [diag.expectedToken][column 15][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( const a = 0;
//  ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//        ^
// [diag.expectedToken] Expected to find '('.
//             ^
// [diag.unexpectedToken] Unexpected text ';'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( enum E { v }
//  ^^^^
// [diag.expectedIdentifierButGotKeyword] 'enum' can't be used as an identifier because it's a keyword.
//       ^
// [diag.expectedToken] Expected to find ','.
//         ^
// [diag.expectedToken] Expected to find ','.
//              ^
// [diag.expectedExecutable][column 17][length 0] Expected a method, getter, setter or operator declaration.
// [diag.expectedToken][column 17][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a(
// ^
// [diag.expectedExecutable][column 4][length 0] Expected a method, getter, setter or operator declaration.
// [diag.expectedToken][column 4][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( final a = 0;
//  ^^^^^
// [diag.missingIdentifier] Expected an identifier.
//  ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: a
          arguments: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: <empty> <synthetic>
            rightParenthesis: ) <synthetic>
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_annotation_topLevel_leftParen_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( int f() {}
//      ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//            ^
// [diag.expectedExecutable][column 15][length 0] Expected a method, getter, setter or operator declaration.
// [diag.expectedToken][column 15][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( void f() {}
//       ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//             ^
// [diag.expectedExecutable][column 16][length 0] Expected a method, getter, setter or operator declaration.
// [diag.expectedToken][column 16][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( int get a => 0;
//      ^^^
// [diag.expectedToken] Expected to find ','.
//          ^
// [diag.expectedToken] Expected to find ','.
//            ^^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//            ^
// [diag.expectedToken] Expected to find ')'.
//               ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                ^
// [diag.unexpectedToken] Unexpected text ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( mixin M {}
//        ^
// [diag.expectedToken] Expected to find ','.
//          ^
// [diag.expectedToken] Expected to find ','.
//            ^
// [diag.expectedExecutable][column 15][length 0] Expected a method, getter, setter or operator declaration.
// [diag.expectedToken][column 15][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( set a(b) {}
//      ^
// [diag.expectedToken] Expected to find ','.
// [diag.namedFunctionExpression] Function expressions can't be named.
//             ^
// [diag.expectedExecutable][column 16][length 0] Expected a method, getter, setter or operator declaration.
// [diag.expectedToken][column 16][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( typedef A = B Function(C, D);
//          ^
// [diag.expectedToken] Expected to find ','.
//                ^^^^^^^^
// [diag.expectedToken] Expected to find ','.
//                              ^
// [diag.unexpectedToken] Unexpected text ';'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a( var a;
//  ^^^
// [diag.missingIdentifier] Expected an identifier.
//  ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: a
          arguments: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: <empty> <synthetic>
            rightParenthesis: ) <synthetic>
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }
}
