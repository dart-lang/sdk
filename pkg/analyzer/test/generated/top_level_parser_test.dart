// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Tests which exercise the parser using a complete compilation unit or
/// compilation unit member.
@reflectiveTest
class TopLevelParserTest extends ParserDiagnosticsTest {
  void test_function_literal_allowed_at_toplevel() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = () {};
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: FunctionExpression
              parameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
              body: BlockFunctionBody
                block: Block
                  leftBracket: {
                  rightBracket: }
      semicolon: ;
''');
  }

  void
  test_function_literal_allowed_in_ArgumentList_in_ConstructorFieldInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : a = f(() {});
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
                expression: MethodInvocation
                  methodName: SimpleIdentifier
                    token: f
                  argumentList: ArgumentList
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
                    rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void
  test_function_literal_allowed_in_IndexExpression_in_ConstructorFieldInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : a = x[() {}];
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
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: x
                  leftBracket: [
                  index: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightBracket: ]
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void
  test_function_literal_allowed_in_ListLiteral_in_ConstructorFieldInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : a = [() {}];
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
                expression: ListLiteral
                  leftBracket: [
                  elements
                    FunctionExpression
                      parameters: FormalParameterList
                        leftParenthesis: (
                        rightParenthesis: )
                      body: BlockFunctionBody
                        block: Block
                          leftBracket: {
                          rightBracket: }
                  rightBracket: ]
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void
  test_function_literal_allowed_in_MapLiteral_in_ConstructorFieldInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : a = {'key': () {}};
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
                expression: SetOrMapLiteral
                  leftBracket: {
                  elements
                    MapLiteralEntry
                      key: SimpleStringLiteral
                        literal: 'key'
                      separator: :
                      value: FunctionExpression
                        parameters: FormalParameterList
                          leftParenthesis: (
                          rightParenthesis: )
                        body: BlockFunctionBody
                          block: Block
                            leftBracket: {
                            rightBracket: }
                  rightBracket: }
                  isMap: false
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void
  test_function_literal_allowed_in_ParenthesizedExpression_in_ConstructorFieldInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : a = (() {});
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
                  expression: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void
  test_function_literal_allowed_in_StringInterpolation_in_ConstructorFieldInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : a = "${() {}}";
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
                expression: StringInterpolation
                  elements
                    InterpolationString
                      contents: "
                    InterpolationExpression
                      leftBracket: ${
                      expression: FunctionExpression
                        parameters: FormalParameterList
                          leftParenthesis: (
                          rightParenthesis: )
                        body: BlockFunctionBody
                          block: Block
                            leftBracket: {
                            rightBracket: }
                      rightBracket: }
                    InterpolationString
                      contents: "
                  stringValue: null
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_import_as_show() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'dart:math' as M show E;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'dart:math'
      asKeyword: as
      prefix: SimpleIdentifier
        token: M
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: E
      semicolon: ;
''');
  }

  void test_import_show_hide() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'import1_lib.dart' show hide, show hide ugly;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'import1_lib.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: hide
            SimpleIdentifier
              token: show
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: ugly
      semicolon: ;
''');
  }

  void test_import_withDocComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
import "foo.dart";
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      documentationComment: Comment
        tokens
          /// Doc
      importKeyword: import
      uri: SimpleStringLiteral
        literal: "foo.dart"
      semicolon: ;
''');
  }

  void test_parse_missing_type_in_list_at_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Future<List<>>
//          ^^
// [diag.expectedTypeName] Expected a type name.
//           ^
// [diag.expectedToken] Expected to find ';'.
//            ^
// [diag.missingIdentifier][column 15][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: Future
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: <empty> <synthetic>
                  rightBracket: >
            rightBracket: >
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_parseClassDeclaration_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract class A {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      abstractKeyword: abstract
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {}
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
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_extends() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_extendsAndImplements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_extendsAndWith() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_extendsAndWithAndImplements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements D {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: D
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_implements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_metadata() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
@B(2)
@C.foo(3)
@d.E.bar(4, 5)
class X {}
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
            token: A
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: B
          arguments: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 2
            rightParenthesis: )
        Annotation
          atSign: @
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: C
            period: .
            identifier: SimpleIdentifier
              token: foo
          arguments: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 3
            rightParenthesis: )
        Annotation
          atSign: @
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: d
            period: .
            identifier: SimpleIdentifier
              token: E
          period: .
          constructorName: SimpleIdentifier
            token: bar
          arguments: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 4
              IntegerLiteral
                literal: 5
            rightParenthesis: )
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: X
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_native() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A native "nativeValue" {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      nativeClause: NativeClause
        nativeKeyword: native
        name: SimpleStringLiteral
          literal: "nativeValue"
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_native_allowedWithFields() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A native 'something' {
  final int x;
  A() {}
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      nativeClause: NativeClause
        nativeKeyword: native
        name: SimpleStringLiteral
          literal: 'something'
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: final
              type: NamedType
                name: int
              variables
                VariableDeclaration
                  name: x
            semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: A
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

  void test_parseClassDeclaration_native_missing_literal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A native {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      nativeClause: NativeClause
        nativeKeyword: native
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var f;
}
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
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_typeAlias_implementsC() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = Object with B implements C;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: Object
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: C
      semicolon: ;
''');
  }

  void test_parseClassDeclaration_typeAlias_withB() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = Object with B;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: Object
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
      semicolon: ;
''');
  }

  void test_parseClassDeclaration_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A<B> {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: B
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_typeParameters_extends_void() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<T extends void>{}
//                ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: NamedType
                name: void
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassDeclaration_withDocumentationComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /// Doc
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseClassTypeAlias_withDocumentationComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
class C = D with E;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      documentationComment: Comment
        tokens
          /// Doc
      typedefKeyword: class
      name: C
      equals: =
      superclass: NamedType
        name: D
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: E
      semicolon: ;
''');
  }

  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract<dynamic> _abstract = new abstract.A();
// [diag.builtInIdentifierAsType][column 1][length 8] The built-in identifier 'abstract' can't be used as a type.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: abstract
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: dynamic
            rightBracket: >
        variables
          VariableDeclaration
            name: _abstract
            equals: =
            initializer: InstanceCreationExpression
              keyword: new
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: abstract
                    period: .
                  name: A
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseCompilationUnit_builtIn_asFunctionName() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isBuiltIn || keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        if (lexeme == 'Function') continue;
        parseTestCodeWithDiagnostics('$lexeme(x) => 0;');
        parseTestCodeWithDiagnostics('class C {$lexeme(x) => 0;}');
      }
    }
  }

  void test_parseCompilationUnit_builtIn_asFunctionName_withTypeParameter() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isBuiltIn || keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        if (lexeme == 'Function') continue;
        // The fasta type resolution phase will report an error
        // on type arguments on `dynamic` (e.g. `dynamic<int>`).
        parseTestCodeWithDiagnostics('$lexeme<T>(x) => 0;');
        parseTestCodeWithDiagnostics('class C {$lexeme<T>(x) => 0;}');
      }
    }
  }

  void test_parseCompilationUnit_builtIn_asGetter() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isBuiltIn || keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseTestCodeWithDiagnostics('get $lexeme => 0;');
        parseTestCodeWithDiagnostics('class C {get $lexeme => 0;}');
      }
    }
  }

  void test_parseCompilationUnit_directives_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library l;

part 'a.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_parseCompilationUnit_directives_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library l;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parseCompilationUnit_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_parseCompilationUnit_exportAsPrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export.A _export = new export.A();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          importPrefix: ImportPrefixReference
            name: export
            period: .
          name: A
        variables
          VariableDeclaration
            name: _export
            equals: =
            initializer: InstanceCreationExpression
              keyword: new
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: export
                    period: .
                  name: A
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export<dynamic> _export = new export.A();
// [diag.builtInIdentifierAsType][column 1][length 6] The built-in identifier 'export' can't be used as a type.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: export
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: dynamic
            rightBracket: >
        variables
          VariableDeclaration
            name: _export
            equals: =
            initializer: InstanceCreationExpression
              keyword: new
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: export
                    period: .
                  name: A
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
operator<dynamic> _operator = new operator.A();
// [diag.builtInIdentifierAsType][column 1][length 8] The built-in identifier 'operator' can't be used as a type.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: operator
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: dynamic
            rightBracket: >
        variables
          VariableDeclaration
            name: _operator
            equals: =
            initializer: InstanceCreationExpression
              keyword: new
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: operator
                    period: .
                  name: A
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseCompilationUnit_pseudo_asNamedType() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseTestCodeWithDiagnostics('$lexeme f;');
        parseTestCodeWithDiagnostics('class C {$lexeme f;}');
        parseTestCodeWithDiagnostics('f($lexeme g) {}');
        parseTestCodeWithDiagnostics('f() {$lexeme g;}');
      }
    }
  }

  void test_parseCompilationUnit_pseudo_prefixed() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseTestCodeWithDiagnostics('M.$lexeme f;');
        parseTestCodeWithDiagnostics('class C {M.$lexeme f;}');
      }
    }
  }

  void test_parseCompilationUnit_script() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
#! /bin/dart
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  scriptTag: ScriptTag
    scriptTag: #! /bin/dart
''');
  }

  void test_parseCompilationUnit_skipFunctionBody_withInterpolation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() {
  "${n}";
}
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
              ExpressionStatement
                expression: StringInterpolation
                  elements
                    InterpolationString
                      contents: "
                    InterpolationExpression
                      leftBracket: ${
                      expression: SimpleIdentifier
                        token: n
                      rightBracket: }
                    InterpolationString
                      contents: "
                  stringValue: null
                semicolon: ;
            rightBracket: }
''');
  }

  void test_parseCompilationUnit_topLevelDeclaration() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {}
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
        rightBracket: }
''');
  }

  void test_parseCompilationUnit_typedefAsPrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef.A _typedef = new typedef.A();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          importPrefix: ImportPrefixReference
            name: typedef
            period: .
          name: A
        variables
          VariableDeclaration
            name: _typedef
            equals: =
            initializer: InstanceCreationExpression
              keyword: new
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: typedef
                    period: .
                  name: A
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_abstractAsPrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract.A _abstract = new abstract.A();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          importPrefix: ImportPrefixReference
            name: abstract
            period: .
          name: A
        variables
          VariableDeclaration
            name: _abstract
            equals: =
            initializer: InstanceCreationExpression
              keyword: new
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: abstract
                    period: .
                  name: A
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {}
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
        rightBracket: }
''');
  }

  void test_parseCompilationUnitMember_classTypeAlias() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract class A = B with C;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      abstractKeyword: abstract
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_constVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
const int x = 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_expressionFunctionBody_tokens() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => 0;
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
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_finalVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_function_external_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external f();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      externalKeyword: external
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_function_external_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external int f();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      externalKeyword: external
      returnType: NamedType
        name: int
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_function_generic_noReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<E>() {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void
  test_parseCompilationUnitMember_function_generic_noReturnType_annotated() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<@a E>() {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              metadata
                Annotation
                  atSign: @
                  name: SimpleIdentifier
                    token: a
              name: E
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

  void test_parseCompilationUnitMember_function_generic_returnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
E f<E>() {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_parseCompilationUnitMember_function_generic_void() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f<T>(T t) {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: void
      name: f
      functionExpression: FunctionExpression
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
            name: t
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_parseCompilationUnitMember_function_gftReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void Function<A>(core.List<core.int> x) f() => null;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
      name: f
      functionExpression: FunctionExpression
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

  void test_parseCompilationUnitMember_function_noReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Function<A>(core.List<core.int> x) f() => null;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
      name: f
      functionExpression: FunctionExpression
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

  void test_parseCompilationUnitMember_function_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() {}
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
            rightBracket: }
''');
  }

  void test_parseCompilationUnitMember_function_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int f() {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_parseCompilationUnitMember_function_void() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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

  void test_parseCompilationUnitMember_getter_external_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external get p;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      externalKeyword: external
      propertyKeyword: get
      name: p
      functionExpression: FunctionExpression
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_getter_external_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external int get p;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      externalKeyword: external
      returnType: NamedType
        name: int
      propertyKeyword: get
      name: p
      functionExpression: FunctionExpression
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_getter_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
get p => 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      propertyKeyword: get
      name: p
      functionExpression: FunctionExpression
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_getter_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int get p => 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: int
      propertyKeyword: get
      name: p
      functionExpression: FunctionExpression
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_setter_external_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external set p(v);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      externalKeyword: external
      propertyKeyword: set
      name: p
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: v
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_setter_external_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external void set p(int v);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      externalKeyword: external
      returnType: NamedType
        name: void
      propertyKeyword: set
      name: p
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: v
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_setter_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
set p(v) {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      propertyKeyword: set
      name: p
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: v
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_parseCompilationUnitMember_setter_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void set p(int v) {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: void
      propertyKeyword: set
      name: p
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: v
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_parseCompilationUnitMember_typeAlias_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract class C = S with M;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      abstractKeyword: abstract
      typedefKeyword: class
      name: C
      equals: =
      superclass: NamedType
        name: S
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: M
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_typeAlias_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<E> = S<E> with M<E> implements I<E>;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: C
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: E
        rightBracket: >
      equals: =
      superclass: NamedType
        name: S
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: E
          rightBracket: >
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: M
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: E
              rightBracket: >
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: I
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: E
              rightBracket: >
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_typeAlias_implements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C = S with M implements I;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: C
      equals: =
      superclass: NamedType
        name: S
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: M
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: I
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_typeAlias_noImplements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C = S with M;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: C
      equals: =
      superclass: NamedType
        name: S
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: M
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: F
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_typedef_withDocComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
typedef F();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      documentationComment: Comment
        tokens
          /// Doc
      typedefKeyword: typedef
      name: F
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_typedVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_variable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_variable_gftType_gftReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Function(int) Function(String) v;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
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
                name: String
            rightParenthesis: )
        variables
          VariableDeclaration
            name: v
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_variable_gftType_noReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Function(int, String) v;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
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

  void test_parseCompilationUnitMember_variable_withDocumentationComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
var x = 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      documentationComment: Comment
        tokens
          /// Doc
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_variableGet() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
String get = null;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: String
        variables
          VariableDeclaration
            name: get
            equals: =
            initializer: NullLiteral
              literal: null
      semicolon: ;
''');
  }

  void test_parseCompilationUnitMember_variableSet() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
String set = null;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: String
        variables
          VariableDeclaration
            name: set
            equals: =
            initializer: NullLiteral
              literal: null
      semicolon: ;
''');
  }

  void test_parseDirective_export() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'lib/lib.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      semicolon: ;
''');
  }

  void test_parseDirective_export_withDocComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
export 'foo.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      documentationComment: Comment
        tokens
          /// Doc
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'foo.dart'
      semicolon: ;
''');
  }

  void test_parseDirective_import() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      semicolon: ;
''');
  }

  void test_parseDirective_library() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library l;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parseDirective_library_1_component() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library a;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          a
      semicolon: ;
''');
  }

  void test_parseDirective_library_2_components() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library a.b;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          a
          .
          b
      semicolon: ;
''');
  }

  void test_parseDirective_library_3_components() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library a.b.c;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          a
          .
          b
          .
          c
      semicolon: ;
''');
  }

  void test_parseDirective_library_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
library l;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parseDirective_library_annotation2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
library l;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parseDirective_library_unnamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      semicolon: ;
''');
  }

  void test_parseDirective_library_withDocumentationComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
library l;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      documentationComment: Comment
        tokens
          /// Doc
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parseDirective_part() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part 'lib/lib.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      semicolon: ;
''');
  }

  void test_parseDirective_part_of_1_component() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of a;
//      ^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          a
      semicolon: ;
''');
  }

  void test_parseDirective_part_of_2_components() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of a.b;
//      ^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          a
          .
          b
      semicolon: ;
''');
  }

  void test_parseDirective_part_of_3_components() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of a.b.c;
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          a
          .
          b
          .
          c
      semicolon: ;
''');
  }

  void test_parseDirective_part_of_withDocumentationComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
part of a;
//      ^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      documentationComment: Comment
        tokens
          /// Doc
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          a
      semicolon: ;
''');
  }

  void test_parseDirective_part_withDocumentationComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
part 'lib.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      documentationComment: Comment
        tokens
          /// Doc
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'lib.dart'
      semicolon: ;
''');
  }

  void test_parseDirective_partOf() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of l;
//      ^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parseDirectives_annotations() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
library l;

@B
import 'foo.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
    ImportDirective
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: B
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'foo.dart'
      semicolon: ;
''');
  }

  void test_parseDirectives_complete() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
#! /bin/dart

library l;

class A {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  scriptTag: ScriptTag
    scriptTag: #! /bin/dart
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseDirectives_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_parseDirectives_mixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library l; class A {} part 'foo.dart';
//                    ^^^^
// [diag.directiveAfterDeclaration] Directives must appear before any declarations.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'foo.dart'
      semicolon: ;
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseDirectives_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library l;

part 'a.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_parseDirectives_script() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
#! /bin/dart
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  scriptTag: ScriptTag
    scriptTag: #! /bin/dart
''');
  }

  void test_parseDirectives_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library l;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parseDirectives_topLevelDeclaration() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {}
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
        rightBracket: }
''');
  }

  void test_parseEnumDeclaration_one() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E { ONE }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: ONE
        rightBracket: }
''');
  }

  void test_parseEnumDeclaration_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E { ONE }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: ONE
        rightBracket: }
''');
  }

  void test_parseEnumDeclaration_two() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E { ONE, TWO }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: ONE
          EnumConstantDeclaration
            name: TWO
        rightBracket: }
''');
  }

  void test_parseEnumDeclaration_withDocComment_onEnum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
enum E { ONE }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      documentationComment: Comment
        tokens
          /// Doc
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: ONE
        rightBracket: }
''');
  }

  void test_parseEnumDeclaration_withDocComment_onValue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  /// Doc
  ONE,
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            documentationComment: Comment
              tokens
                /// Doc
            name: ONE
        rightBracket: }
''');
  }

  void test_parseEnumDeclaration_withDocComment_onValue_annotated() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  /// Doc
  @annotation
  ONE,
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            documentationComment: Comment
              tokens
                /// Doc
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: annotation
            name: ONE
        rightBracket: }
''');
  }

  void test_parseExportDirective_configuration_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'lib/lib.dart' if (a) 'b.dart' if (c) 'd.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              a
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'b.dart'
          resolvedUri: <null>
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              c
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'd.dart'
          resolvedUri: <null>
      semicolon: ;
''');
  }

  void test_parseExportDirective_configuration_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'lib/lib.dart' if (a.b == 'c.dart') '';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              a
              .
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: 'c.dart'
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: ''
          resolvedUri: <null>
      semicolon: ;
''');
  }

  void test_parseExportDirective_hide() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'lib/lib.dart' hide A, B;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ;
''');
  }

  void test_parseExportDirective_hide_show() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'lib/lib.dart' hide A show B;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: B
      semicolon: ;
''');
  }

  void test_parseExportDirective_noCombinator() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'lib/lib.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      semicolon: ;
''');
  }

  void test_parseExportDirective_show() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'lib/lib.dart' show A, B;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ;
''');
  }

  void test_parseExportDirective_show_hide() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'lib/lib.dart' show B hide A;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: B
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
      semicolon: ;
''');
  }

  void test_parseFunctionDeclaration_function() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
T f() {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      documentationComment: Comment
        tokens
          /// Doc
      returnType: NamedType
        name: T
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

  void test_parseFunctionDeclaration_functionWithTypeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
T f<E>() {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      documentationComment: Comment
        tokens
          /// Doc
      returnType: NamedType
        name: T
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_parseFunctionDeclaration_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
T get p => 0;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      documentationComment: Comment
        tokens
          /// Doc
      returnType: NamedType
        name: T
      propertyKeyword: get
      name: p
      functionExpression: FunctionExpression
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
''');
  }

  void test_parseFunctionDeclaration_metadata() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
T f(@A a, @B(2) Foo b, {@C.foo(3) c: 0, @d.E.bar(4, 5) x: 0}) {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: T
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: A
            name: a
          parameter: RegularFormalParameter
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: B
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    IntegerLiteral
                      literal: 2
                  rightParenthesis: )
            type: NamedType
              name: Foo
            name: b
          leftDelimiter: {
          parameter: RegularFormalParameter
            metadata
              Annotation
                atSign: @
                name: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: C
                  period: .
                  identifier: SimpleIdentifier
                    token: foo
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    IntegerLiteral
                      literal: 3
                  rightParenthesis: )
            name: c
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: IntegerLiteral
                literal: 0
          parameter: RegularFormalParameter
            metadata
              Annotation
                atSign: @
                name: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: d
                  period: .
                  identifier: SimpleIdentifier
                    token: E
                period: .
                constructorName: SimpleIdentifier
                  token: bar
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    IntegerLiteral
                      literal: 4
                    IntegerLiteral
                      literal: 5
                  rightParenthesis: )
            name: x
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: IntegerLiteral
                literal: 0
          rightDelimiter: }
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_parseFunctionDeclaration_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
T set p(v) {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      documentationComment: Comment
        tokens
          /// Doc
      returnType: NamedType
        name: T
      propertyKeyword: set
      name: p
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: v
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_parseGenericTypeAlias_noTypeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = int Function(int);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      equals: =
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
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<T> = T Function(T);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: T
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: T
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_typeParameters2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<T> = T Function(T);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: T
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: T
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_typeParameters3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<A, B, C> = Function(A a, B b, C c);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
          TypeParameter
            name: B
          TypeParameter
            name: C
        rightBracket: >
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: A
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: B
            name: b
          parameter: RegularFormalParameter
            type: NamedType
              name: C
            name: c
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_typeParameters3_gtEq() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<A, B, C> = Function(A a, B b, C c);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
          TypeParameter
            name: B
          TypeParameter
            name: C
        rightBracket: >
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: A
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: B
            name: b
          parameter: RegularFormalParameter
            type: NamedType
              name: C
            name: c
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_typeParameters_extends() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<A, B, C extends D<E>> = Function(A a, B b, C c);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
          TypeParameter
            name: B
          TypeParameter
            name: C
            extendsKeyword: extends
            bound: NamedType
              name: D
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: E
                rightBracket: >
        rightBracket: >
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: A
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: B
            name: b
          parameter: RegularFormalParameter
            type: NamedType
              name: C
            name: c
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_typeParameters_extends3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<A, B, C extends D<E, G, H>> = Function(A a, B b, C c);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
          TypeParameter
            name: B
          TypeParameter
            name: C
            extendsKeyword: extends
            bound: NamedType
              name: D
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: E
                  NamedType
                    name: G
                  NamedType
                    name: H
                rightBracket: >
        rightBracket: >
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: A
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: B
            name: b
          parameter: RegularFormalParameter
            type: NamedType
              name: C
            name: c
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_typeParameters_extends3_gtGtEq() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<A, B, C extends D<E, G, H>> = Function(A a, B b, C c);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
          TypeParameter
            name: B
          TypeParameter
            name: C
            extendsKeyword: extends
            bound: NamedType
              name: D
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: E
                  NamedType
                    name: G
                  NamedType
                    name: H
                rightBracket: >
        rightBracket: >
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: A
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: B
            name: b
          parameter: RegularFormalParameter
            type: NamedType
              name: C
            name: c
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_typeParameters_extends_gtGtEq() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<A, B, C extends D<E>> = Function(A a, B b, C c);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
          TypeParameter
            name: B
          TypeParameter
            name: C
            extendsKeyword: extends
            bound: NamedType
              name: D
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: E
                rightBracket: >
        rightBracket: >
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: A
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: B
            name: b
          parameter: RegularFormalParameter
            type: NamedType
              name: C
            name: c
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_TypeParametersInProgress1() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F< = int Function(int);
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: <empty> <synthetic>
        rightBracket: > <synthetic>
      equals: =
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
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_TypeParametersInProgress2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<>= int Function(int);
//        ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: <empty> <synthetic>
        rightBracket: >
      equals: =
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
      semicolon: ;
''');
  }

  void test_parseGenericTypeAlias_TypeParametersInProgress3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<> = int Function(int);
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: <empty> <synthetic>
        rightBracket: >
      equals: =
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
      semicolon: ;
''');
  }

  void test_parseImportDirective_configuration_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart' if (a) 'b.dart' if (c) 'd.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              a
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'b.dart'
          resolvedUri: <null>
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              c
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'd.dart'
          resolvedUri: <null>
      semicolon: ;
''');
  }

  void test_parseImportDirective_configuration_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart' if (a.b == 'c.dart') '';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              a
              .
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: 'c.dart'
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: ''
          resolvedUri: <null>
      semicolon: ;
''');
  }

  void test_parseImportDirective_deferred() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart' deferred as a;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      deferredKeyword: deferred
      asKeyword: as
      prefix: SimpleIdentifier
        token: a
      semicolon: ;
''');
  }

  void test_parseImportDirective_hide() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart' hide A, B;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ;
''');
  }

  void test_parseImportDirective_noCombinator() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      semicolon: ;
''');
  }

  void test_parseImportDirective_prefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart' as a;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: a
      semicolon: ;
''');
  }

  void test_parseImportDirective_prefix_hide_show() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart' as a hide A show B;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: a
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: B
      semicolon: ;
''');
  }

  void test_parseImportDirective_prefix_show_hide() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart' as a show B hide A;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: a
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: B
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
      semicolon: ;
''');
  }

  void test_parseImportDirective_show() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'lib/lib.dart' show A, B;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ;
''');
  }

  void test_parseLibraryDirective() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library l;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parseMixinDeclaration_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseMixinDeclaration_implements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseMixinDeclaration_implements2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B<T>, C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: T
              rightBracket: >
          NamedType
            name: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseMixinDeclaration_metadata() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@Z
mixin A {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: Z
      mixinKeyword: mixin
      name: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseMixinDeclaration_on() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseMixinDeclaration_on2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, C<T> {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: C
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: T
              rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseMixinDeclaration_onAndImplements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseMixinDeclaration_simple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A {
  int f;
  int get g => f;
  set s(int v) {
    f = v;
  }

  int add(int v) => f = f + v;
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              type: NamedType
                name: int
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
          MethodDeclaration
            returnType: NamedType
              name: int
            propertyKeyword: get
            name: g
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: SimpleIdentifier
                token: f
              semicolon: ;
          MethodDeclaration
            propertyKeyword: set
            name: s
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: v
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                statements
                  ExpressionStatement
                    expression: AssignmentExpression
                      leftHandSide: SimpleIdentifier
                        token: f
                      operator: =
                      rightHandSide: SimpleIdentifier
                        token: v
                    semicolon: ;
                rightBracket: }
          MethodDeclaration
            returnType: NamedType
              name: int
            name: add
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: v
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: AssignmentExpression
                leftHandSide: SimpleIdentifier
                  token: f
                operator: =
                rightHandSide: BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: f
                  operator: +
                  rightOperand: SimpleIdentifier
                    token: v
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseMixinDeclaration_withDocumentationComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
mixin M {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      documentationComment: Comment
        tokens
          /// Doc
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parsePartDirective() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part 'lib/lib.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'lib/lib.dart'
      semicolon: ;
''');
  }

  void test_parsePartOfDirective_name() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of l;
//      ^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_parsePartOfDirective_uri() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'lib.dart';
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'lib.dart'
      semicolon: ;
''');
  }

  void test_parseTopLevelVariable_external() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external int i;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      externalKeyword: external
      variables: VariableDeclarationList
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: i
      semicolon: ;
''');
  }

  void test_parseTopLevelVariable_external_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external late int? i;
// [diag.externalLateField][column 1][length 8] External fields cannot be late.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      externalKeyword: external
      variables: VariableDeclarationList
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

  void test_parseTopLevelVariable_external_late_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external late final int? i;
// [diag.externalLateField][column 1][length 8] External fields cannot be late.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      externalKeyword: external
      variables: VariableDeclarationList
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

  void test_parseTopLevelVariable_final_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final late a;
//    ^^^^
// [diag.modifierOutOfOrder] The modifier 'late' should be before the modifier 'final'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        lateKeyword: late
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseTopLevelVariable_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
late a;
//   ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        lateKeyword: late
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseTopLevelVariable_late_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
late final a;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        lateKeyword: late
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseTopLevelVariable_late_init() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
late a = 0;
//   ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        lateKeyword: late
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_parseTopLevelVariable_late_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
late A a;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        lateKeyword: late
        type: NamedType
          name: A
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseTopLevelVariable_non_external() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int i;
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: i
      semicolon: ;
''');
  }

  void test_parseTypeAlias_function_noParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef bool F();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: bool
      name: F
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_function_noReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: F
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_function_parameterizedReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef A<B> F();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: B
          rightBracket: >
      name: F
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_function_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef bool F(Object value);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: bool
      name: F
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: RegularFormalParameter
          type: NamedType
            name: Object
          name: value
        rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_function_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef bool F<E>();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: bool
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: E
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_function_voidReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef void F();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: void
      name: F
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_noParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = bool Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: bool
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_noReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_parameterizedReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = A<B> Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: A
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: B
            rightBracket: >
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = bool Function(Object value);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: bool
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: Object
            name: value
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = bool Function<E>();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: bool
        functionKeyword: Function
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: E
          rightBracket: >
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_typeParameters_noParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<T> = bool Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: bool
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_typeParameters_noReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<T> = Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void
  test_parseTypeAlias_genericFunction_typeParameters_parameterizedReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<T> = A<B> Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: A
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: B
            rightBracket: >
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_typeParameters_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<T> = bool Function(Object value);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: bool
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: Object
            name: value
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_typeParameters_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<T> = bool Function<E>();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: bool
        functionKeyword: Function
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: E
          rightBracket: >
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_typeParameters_voidReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<T> = void Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: void
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_voidReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = void Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: void
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeAlias_genericFunction_withDocComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Doc
typedef F = bool Function();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      documentationComment: Comment
        tokens
          /// Doc
      typedefKeyword: typedef
      name: F
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: bool
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseTypeVariable_withDocumentationComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A<
  /// Doc
  B
> {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              documentationComment: Comment
                tokens
                  /// Doc
              name: B
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }
}
