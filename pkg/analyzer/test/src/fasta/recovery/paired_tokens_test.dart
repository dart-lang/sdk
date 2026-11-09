// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AngleBracketsTest);
    defineReflectiveTests(BracesTest);
    defineReflectiveTests(BracketsTest);
    defineReflectiveTests(ParenthesesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Test how well the parser recovers when angle brackets (`<` and `>`) are
/// mismatched.
@reflectiveTest
class AngleBracketsTest extends ParserDiagnosticsTest {
  void test_classTypeAlias_annotationWithTypeArguments_sharedCloser() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C = Object with List<@a<int>>
//                         ^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//                                ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find ';'.
''');

    var node = parseResult.findNode.singleClassTypeAlias;
    assertParsedNodeText(node, withTokenPreviousNext: true, r'''
ClassTypeAlias2
  classKeyword: T0 class
    next: T1 |C|
  name: T1 C
    previous: T0 |class|
    next: T2 |=|
  equals: T2 =
    previous: T1 |C|
    next: T3 |Object|
  superclass: NamedType
    name: T3 Object
      previous: T2 |=|
      next: T4 |with|
  withClause: WithClause
    withKeyword: T4 with
      previous: T3 |Object|
      next: T5 |List|
    mixinTypes
      NamedType
        name: T5 List
          previous: T4 |with|
          next: T6 |<|
        typeArguments: TypeArgumentList
          leftBracket: T6 <
            previous: T5 |List|
            next: T7 |@|
          arguments
            NamedType
              name: T8 <empty> <synthetic>
                  previousX: T9 >
                      previousX: T10 int
                          previousX: T11 <
                              previousX: T12 a
                                previous: T7 |@|
                                next: T11 |<|
                            next: T10 |int|
                        next: T9 |>|
                    next: T8 ||
                next: T13 |>|
          rightBracket: T13 >
            previous: T8 ||
            next: T14 |;|
  body: SemicolonInstanceDeclarationBody
    semicolon: T14 ; <synthetic>
      previous: T13 |>|
      next: T15 ||
V1: ClassTypeAlias
  typedefKeyword: T0 class
    next: T1 |C|
  name: T1 C
    previous: T0 |class|
    next: T2 |=|
  equals: T2 =
    previous: T1 |C|
    next: T3 |Object|
  superclass: NamedType
    name: T3 Object
      previous: T2 |=|
      next: T4 |with|
  withClause: WithClause
    withKeyword: T4 with
      previous: T3 |Object|
      next: T5 |List|
    mixinTypes
      NamedType
        name: T5 List
          previous: T4 |with|
          next: T6 |<|
        typeArguments: TypeArgumentList
          leftBracket: T6 <
            previous: T5 |List|
            next: T7 |@|
          arguments
            NamedType
              name: T8 <empty> <synthetic>
                previous: T9 |>|
                next: T13 |>|
          rightBracket: T13 >
            previous: T8 ||
            next: T14 |;|
  semicolon: T14 ; <synthetic>
    previous: T13 |>|
    next: T15 ||
''');
  }

  void test_listPattern_annotationWithTypeArguments_sharedCloser() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case <@a<int>>[]) {}
//            ^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//                   ^
// [diag.expectedTypeName] Expected a type name.
}
''');

    var node = parseResult.findNode.singleListPattern;
    assertParsedNodeText(node, withTokenPreviousNext: true, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: T0 <
        previousX: T1 case
            previousX: T2 x
                previousX: T3 (
                    previousX: T4 if
                        previousX: T5 {
                            previousX: T6 )
                                previousX: T7 x
                                    previousX: T8 (
                                        previousX: T9 f
                                            previousX: T10 void
                                              next: T9 |f|
                                          next: T8 |(|
                                      next: T7 |x|
                                  next: T6 |)|
                              next: T5 |{|
                          next: T4 |if|
                      next: T3 |(|
                  next: T2 |x|
              next: T1 |case|
          next: T0 |<|
      next: T11 |@|
    arguments
      NamedType
        name: T12 <empty> <synthetic>
            previousX: T13 >
                previousX: T14 int
                    previousX: T15 <
                        previousX: T16 a
                          previous: T11 |@|
                          next: T15 |<|
                      next: T14 |int|
                  next: T13 |>|
              next: T12 ||
          next: T17 |>|
    rightBracket: T17 >
      previous: T12 ||
      next: T18 |[|
  leftBracket: T18 [
    previous: T17 |>|
    next: T19 |]|
  rightBracket: T19 ]
    previous: T18 |[|
    next: T20 |)|
''');
  }

  void test_metadata_annotationWithTypeArguments_sharedCloser() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@a<@b<int>>
// ^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//        ^
// [diag.expectedTypeName] Expected a type name.
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
class C {}
''');

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, withTokenPreviousNext: true, r'''
ClassDeclaration2
  metadata
    Annotation
      atSign: T0 @
        next: T1 |a|
      expression: ParsedTypeArguments
        operand: ParsedUnqualifiedName
          name: T1 a
            previous: T0 |@|
            next: T2 |<|
        typeArguments: TypeArgumentList
          leftBracket: T2 <
            previous: T1 |a|
            next: T3 |@|
          arguments
            NamedType
              name: T4 <empty> <synthetic>
                  previousX: T5 >
                      previousX: T6 int
                          previousX: T7 <
                              previousX: T8 b
                                previous: T3 |@|
                                next: T7 |<|
                            next: T6 |int|
                        next: T5 |>|
                    next: T4 ||
                next: T9 |>|
          rightBracket: T9 >
            previous: T4 ||
            next: T10 |class|
  classKeyword: T10 class
    previous: T9 |>|
    next: T11 |C|
  namePart: NameWithTypeParameters
    typeName: T11 C
      previous: T10 |class|
      next: T12 |{|
  body: BlockInstanceDeclarationBody
    leftBracket: T12 {
      previous: T11 |C|
      next: T13 |}|
    rightBracket: T13 }
      previous: T12 |{|
      next: T14 ||
V1: ClassDeclaration
  metadata
    Annotation
      atSign: T0 @
        next: T1 |a|
      name: SimpleIdentifier
        token: T1 a
          previous: T0 |@|
          next: T2 |<|
      typeArguments: TypeArgumentList
        leftBracket: T2 <
          previous: T1 |a|
          next: T3 |@|
        arguments
          NamedType
            name: T4 <empty> <synthetic>
              previous: T5 |>|
              next: T9 |>|
        rightBracket: T9 >
          previous: T4 ||
          next: T10 |class|
  classKeyword: T10 class
    previous: T9 |>|
    next: T11 |C|
  namePart: NameWithTypeParameters
    typeName: T11 C
      previous: T10 |class|
      next: T12 |{|
  body: BlockClassBody
    leftBracket: T12 {
      previous: T11 |C|
      next: T13 |}|
    rightBracket: T13 }
      previous: T12 |{|
      next: T14 ||
''');
  }

  void test_recordType_annotationWithTypeArguments_sharedCloser() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
(@a<int>> x, int y) z;
//     ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
//      ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find ')'.
//                ^
// [diag.recordTypeOnePositionalNoTrailingComma] A record type with exactly one positional field requires a trailing comma.
''');

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            metadata
              Annotation
                atSign: @
                expression: ParsedTypeArguments
                  operand: ParsedUnqualifiedName
                    name: a
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: int
                    rightBracket: >
                name: SimpleIdentifier
                  token: a
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                  rightBracket: >
            type: NamedType
              name: <empty> <synthetic>
        rightParenthesis: )
      variables
        TopLevelVariable
          name: z
      semicolon: ;
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              metadata
                Annotation
                  atSign: @
                  name: SimpleIdentifier
                    token: a
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: int
                    rightBracket: >
              type: NamedType
                name: <empty> <synthetic>
          rightParenthesis: )
        variables
          VariableDeclaration
            name: z
      semicolon: ;
''');
  }

  void test_recordType_annotationWithTypeArguments_unclosed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
(@a< x, int y) z;
//^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
// ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find ')'.
//           ^
// [diag.recordTypeOnePositionalNoTrailingComma] A record type with exactly one positional field requires a trailing comma.
''');

    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    assertParsedNodeText(node, withTokenPreviousNext: true, r'''
TopLevelVariablesDeclaration
  type: RecordTypeAnnotation
    leftParenthesis: T0 (
      next: T1 |@|
    positionalFields
      RecordTypeAnnotationPositionalField
        metadata
          Annotation
            atSign: T1 @
              previous: T0 |(|
              next: T2 |a|
            expression: ParsedUnqualifiedName
              name: T2 a
                previous: T1 |@|
                next: T3 ||
        type: NamedType
          name: T3 <empty> <synthetic>
            previous: T2 |a|
            next: T4 |<|
    rightParenthesis: T5 )
        previousX: T6 y
            previousX: T7 int
                previousX: T8 ,
                    previousX: T9 x
                      previous: T4 |<|
                      next: T8 |,|
                  next: T7 |int|
              next: T6 |y|
          next: T5 |)|
      next: T10 |z|
  variables
    TopLevelVariable
      name: T10 z
        previous: T5 |)|
        next: T11 |;|
  semicolon: T11 ;
    previous: T10 |z|
    next: T12 ||
V1: TopLevelVariableDeclaration
  variables: VariableDeclarationList
    type: RecordTypeAnnotation
      leftParenthesis: T0 (
        next: T1 |@|
      positionalFields
        RecordTypeAnnotationPositionalField
          metadata
            Annotation
              atSign: T1 @
                previous: T0 |(|
                next: T2 |a|
              name: SimpleIdentifier
                token: T2 a
                  previous: T1 |@|
                  next: T3 ||
          type: NamedType
            name: T3 <empty> <synthetic>
              previous: T2 |a|
              next: T4 |<|
      rightParenthesis: T5 )
        previous: T6 |y|
        next: T10 |z|
    variables
      VariableDeclaration
        name: T10 z
          previous: T5 |)|
          next: T11 |;|
  semicolon: T11 ;
    previous: T10 |z|
    next: T12 ||
''');
  }

  void test_typeArguments_annotationWithTypeArguments_sharedCloser() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<@a<int>> x;
//   ^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//          ^
// [diag.expectedTypeName] Expected a type name.
''');

    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    assertParsedNodeText(node, withTokenPreviousNext: true, r'''
TopLevelVariablesDeclaration
  type: NamedType
    name: T0 List
      next: T1 |<|
    typeArguments: TypeArgumentList
      leftBracket: T1 <
        previous: T0 |List|
        next: T2 |@|
      arguments
        NamedType
          name: T3 <empty> <synthetic>
              previousX: T4 >
                  previousX: T5 int
                      previousX: T6 <
                          previousX: T7 a
                            previous: T2 |@|
                            next: T6 |<|
                        next: T5 |int|
                    next: T4 |>|
                next: T3 ||
            next: T8 |>|
      rightBracket: T8 >
        previous: T3 ||
        next: T9 |x|
  variables
    TopLevelVariable
      name: T9 x
        previous: T8 |>|
        next: T10 |;|
  semicolon: T10 ;
    previous: T9 |x|
    next: T11 ||
V1: TopLevelVariableDeclaration
  variables: VariableDeclarationList
    type: NamedType
      name: T0 List
        next: T1 |<|
      typeArguments: TypeArgumentList
        leftBracket: T1 <
          previous: T0 |List|
          next: T2 |@|
        arguments
          NamedType
            name: T3 <empty> <synthetic>
              previous: T4 |>|
              next: T8 |>|
        rightBracket: T8 >
          previous: T3 ||
          next: T9 |x|
    variables
      VariableDeclaration
        name: T9 x
          previous: T8 |>|
          next: T10 |;|
  semicolon: T10 ;
    previous: T9 |x|
    next: T11 ||
''');
  }

  void test_typeArguments_annotationWithTypeArguments_sharedCloser_gtGtGt() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<@a<List<int>>> x;
//   ^^^^^^^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//                ^
// [diag.expectedTypeName] Expected a type name.
''');

    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    assertParsedNodeText(node, withTokenPreviousNext: true, r'''
TopLevelVariablesDeclaration
  type: NamedType
    name: T0 List
      next: T1 |<|
    typeArguments: TypeArgumentList
      leftBracket: T1 <
        previous: T0 |List|
        next: T2 |@|
      arguments
        NamedType
          name: T3 <empty> <synthetic>
              previousX: T4 >
                  previousX: T5 >
                      previousX: T6 int
                          previousX: T7 <
                              previousX: T8 List
                                  previousX: T9 <
                                      previousX: T10 a
                                        previous: T2 |@|
                                        next: T9 |<|
                                    next: T8 |List|
                                next: T7 |<|
                            next: T6 |int|
                        next: T5 |>|
                    next: T4 |>|
                next: T3 ||
            next: T11 |>|
      rightBracket: T11 >
        previous: T3 ||
        next: T12 |x|
  variables
    TopLevelVariable
      name: T12 x
        previous: T11 |>|
        next: T13 |;|
  semicolon: T13 ;
    previous: T12 |x|
    next: T14 ||
V1: TopLevelVariableDeclaration
  variables: VariableDeclarationList
    type: NamedType
      name: T0 List
        next: T1 |<|
      typeArguments: TypeArgumentList
        leftBracket: T1 <
          previous: T0 |List|
          next: T2 |@|
        arguments
          NamedType
            name: T3 <empty> <synthetic>
              previous: T4 |>|
              next: T11 |>|
        rightBracket: T11 >
          previous: T3 ||
          next: T12 |x|
    variables
      VariableDeclaration
        name: T12 x
          previous: T11 |>|
          next: T13 |;|
  semicolon: T13 ;
    previous: T12 |x|
    next: T14 ||
''');
  }

  void test_typeArguments_annotationWithTypeArguments_sharedCloser_second() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Map<@a<int>, @b<int>> x;
//  ^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//         ^
// [diag.expectedTypeName] Expected a type name.
//           ^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//                  ^
// [diag.expectedTypeName] Expected a type name.
''');

    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    assertParsedNodeText(node, withTokenPreviousNext: true, r'''
TopLevelVariablesDeclaration
  type: NamedType
    name: T0 Map
      next: T1 |<|
    typeArguments: TypeArgumentList
      leftBracket: T1 <
        previous: T0 |Map|
        next: T2 |@|
      arguments
        NamedType
          name: T3 <empty> <synthetic>
              previousX: T4 >
                  previousX: T5 int
                      previousX: T6 <
                          previousX: T7 a
                            previous: T2 |@|
                            next: T6 |<|
                        next: T5 |int|
                    next: T4 |>|
                next: T3 ||
            next: T8 |,|
        NamedType
          name: T9 <empty> <synthetic>
              previousX: T10 >
                  previousX: T11 int
                      previousX: T12 <
                          previousX: T13 b
                              previousX: T14 @
                                previous: T8 |,|
                                next: T13 |b|
                            next: T12 |<|
                        next: T11 |int|
                    next: T10 |>|
                next: T9 ||
            next: T15 |>|
      rightBracket: T15 >
        previous: T9 ||
        next: T16 |x|
  variables
    TopLevelVariable
      name: T16 x
        previous: T15 |>|
        next: T17 |;|
  semicolon: T17 ;
    previous: T16 |x|
    next: T18 ||
V1: TopLevelVariableDeclaration
  variables: VariableDeclarationList
    type: NamedType
      name: T0 Map
        next: T1 |<|
      typeArguments: TypeArgumentList
        leftBracket: T1 <
          previous: T0 |Map|
          next: T2 |@|
        arguments
          NamedType
            name: T3 <empty> <synthetic>
              previous: T4 |>|
              next: T8 |,|
          NamedType
            name: T9 <empty> <synthetic>
              previous: T10 |>|
              next: T15 |>|
        rightBracket: T15 >
          previous: T9 ||
          next: T16 |x|
    variables
      VariableDeclaration
        name: T16 x
          previous: T15 |>|
          next: T17 |;|
  semicolon: T17 ;
    previous: T16 |x|
    next: T18 ||
''');
  }

  void test_typeArguments_annotationWithTypeArguments_unclosed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
const x = null as List<@a<;
//                     ^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//                       ^
// [diag.expectedTypeName] Expected a type name.
//                        ^
// [diag.missingIdentifier] Expected an identifier.
''');

    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    assertParsedNodeText(node, withTokenPreviousNext: true, r'''
TopLevelVariablesDeclaration
  constFinalOrVarKeyword: T0 const
    next: T1 |x|
  variables
    TopLevelVariable
      name: T1 x
        previous: T0 |const|
        next: T2 |=|
      equals: T2 =
        previous: T1 |x|
        next: T3 |null|
      initializer: BinaryOperatorInvocation
        leftOperand: AsExpression
          expression2: NullLiteral
            literal: T3 null
              previous: T2 |=|
              next: T4 |as|
          asOperator: T4 as
            previous: T3 |null|
            next: T5 |List|
          type: NamedType
            name: T5 List
              previous: T4 |as|
              next: T6 |<|
            typeArguments: TypeArgumentList
              leftBracket: T6 <
                previous: T5 |List|
                next: T7 |@|
              arguments
                NamedType
                  name: T8 <empty> <synthetic>
                      previousX: T9 a
                        previous: T7 |@|
                        next: T8 ||
                    next: T10 |>|
              rightBracket: T10 > <synthetic>
                previous: T8 ||
                next: T11 |<|
        operator: T11 <
          previous: T10 |>|
          next: T12 ||
        rightOperand: ParsedUnqualifiedName
          name: T12 <empty> <synthetic>
            previous: T11 |<|
            next: T13 |;|
        binaryOperator: lessThan
  semicolon: T13 ;
    previous: T12 ||
    next: T14 ||
V1: TopLevelVariableDeclaration
  variables: VariableDeclarationList
    keyword: T0 const
      next: T1 |x|
    variables
      VariableDeclaration
        name: T1 x
          previous: T0 |const|
          next: T2 |=|
        equals: T2 =
          previous: T1 |x|
          next: T3 |null|
        initializer: BinaryExpression
          leftOperand: AsExpression
            expression: NullLiteral
              literal: T3 null
                previous: T2 |=|
                next: T4 |as|
            asOperator: T4 as
              previous: T3 |null|
              next: T5 |List|
            type: NamedType
              name: T5 List
                previous: T4 |as|
                next: T6 |<|
              typeArguments: TypeArgumentList
                leftBracket: T6 <
                  previous: T5 |List|
                  next: T7 |@|
                arguments
                  NamedType
                    name: T8 <empty> <synthetic>
                      previous: T9 |a|
                      next: T10 |>|
                rightBracket: T10 > <synthetic>
                  previous: T8 ||
                  next: T11 |<|
          operator: T11 <
            previous: T10 |>|
            next: T12 ||
          rightOperand: SimpleIdentifier
            token: T12 <empty> <synthetic>
              previous: T11 |<|
              next: T13 |;|
  semicolon: T13 ;
    previous: T12 ||
    next: T14 ||
''');
  }

  void test_typeArguments_inner_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<List<int>
//           ^
// [diag.expectedToken] Expected to find '>'.
// [diag.expectedToken] Expected to find ';'.
//            ^
// [diag.missingIdentifier][column 15][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
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
                    name: int
                rightBracket: >
          rightBracket: > <synthetic>
      variables
        TopLevelVariable
          name: <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
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
                      name: int
                  rightBracket: >
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typeArguments_inner_last2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<List<int> f;
//           ^
// [diag.expectedToken] Expected to find '>'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
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
                    name: int
                rightBracket: >
          rightBracket: > <synthetic>
      variables
        TopLevelVariable
          name: f
      semicolon: ;
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
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
                      name: int
                  rightBracket: >
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeArguments_inner_notLast() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Map<List<int, List<String>>
//                        ^
// [diag.expectedToken] Expected to find '>'.
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.missingIdentifier][column 28][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      type: NamedType
        name: Map
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: List
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: int
                  NamedType
                    name: List
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: String
                      rightBracket: >
                rightBracket: >
          rightBracket: > <synthetic>
      variables
        TopLevelVariable
          name: <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: Map
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                    NamedType
                      name: List
                      typeArguments: TypeArgumentList
                        leftBracket: <
                        arguments
                          NamedType
                            name: String
                        rightBracket: >
                  rightBracket: >
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typeArguments_inner_notLast2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Map<List<int, List<String>> f;
//                        ^
// [diag.expectedToken] Expected to find '>'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      type: NamedType
        name: Map
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: List
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: int
                  NamedType
                    name: List
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: String
                      rightBracket: >
                rightBracket: >
          rightBracket: > <synthetic>
      variables
        TopLevelVariable
          name: f
      semicolon: ;
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: Map
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                    NamedType
                      name: List
                      typeArguments: TypeArgumentList
                        leftBracket: <
                        arguments
                          NamedType
                            name: String
                        rightBracket: >
                  rightBracket: >
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeArguments_missing_comma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<int double> f;
//       ^^^^^^
// [diag.expectedToken] Expected to find ','.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      type: NamedType
        name: List
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
            NamedType
              name: double
          rightBracket: >
      variables
        TopLevelVariable
          name: f
      semicolon: ;
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: List
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: int
              NamedType
                name: double
            rightBracket: >
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeArguments_outer_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<int
//   ^^^
// [diag.expectedToken] Expected to find '>'.
// [diag.expectedToken] Expected to find ';'.
//      ^
// [diag.missingIdentifier][column 9][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      type: NamedType
        name: List
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: > <synthetic>
      variables
        TopLevelVariable
          name: <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: List
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: int
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typeArguments_outer_last2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<int f;
//   ^^^
// [diag.expectedToken] Expected to find '>'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      type: NamedType
        name: List
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: > <synthetic>
      variables
        TopLevelVariable
          name: f
      semicolon: ;
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: List
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: int
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeParameters_annotationWithTypeArguments_sharedCloser() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<@a<int>> {}
//            ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    ClassDeclaration2
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              metadata
                Annotation
                  atSign: @
                  expression: ParsedTypeArguments
                    operand: ParsedUnqualifiedName
                      name: a
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: int
                      rightBracket: >
                  name: SimpleIdentifier
                    token: a
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: int
                    rightBracket: >
              name: <empty> <synthetic>
          rightBracket: >
      body: BlockInstanceDeclarationBody
        leftBracket: {
        rightBracket: }
  declarations(v1)
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              metadata
                Annotation
                  atSign: @
                  name: SimpleIdentifier
                    token: a
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: int
                    rightBracket: >
              name: <empty> <synthetic>
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_typeParameters_annotationWithTypeArguments_unclosed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<@a< {}
//       ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
//        ^
// [diag.missingIdentifier] Expected an identifier.
//           ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    ClassDeclaration2
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              metadata
                Annotation
                  atSign: @
                  expression: ParsedUnqualifiedName
                    name: a
                  name: SimpleIdentifier
                    token: a
              name: <empty> <synthetic>
          rightBracket: > <synthetic>
      body: BlockInstanceDeclarationBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
  declarations(v1)
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              metadata
                Annotation
                  atSign: @
                  name: SimpleIdentifier
                    token: a
              name: <empty> <synthetic>
          rightBracket: > <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_typeParameters_extraGt() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T>>() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.topLevelOperator] Operators must be declared within a class.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      formalParameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      body: BlockFunctionBody
        block: Block
          leftBracket: { <synthetic>
          rightBracket: } <synthetic>
    TopLevelFunctionDeclaration
      name: #synthetic_function_4 <synthetic>
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: NullLiteral
          literal: null
        semicolon: ;
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
          rightBracket: >
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: #synthetic_function_4 <synthetic>
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

  void test_typeParameters_funct() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T extends Function()() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//                   ^
// [diag.expectedToken] Expected to find '>'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            extendsKeyword: extends
            bound: GenericFunctionType
              functionKeyword: Function
              parameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
        rightBracket: > <synthetic>
      formalParameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: NullLiteral
          literal: null
        semicolon: ;
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: GenericFunctionType
                functionKeyword: Function
                parameters: FormalParameterList
                  leftParenthesis: (
                  rightParenthesis: )
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_funct2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T extends Function<X>()() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//                      ^
// [diag.expectedToken] Expected to find '>'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            extendsKeyword: extends
            bound: GenericFunctionType
              functionKeyword: Function
              typeParameters: TypeParameterList
                leftBracket: <
                typeParameters
                  TypeParameter
                    name: X
                rightBracket: >
              parameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
        rightBracket: > <synthetic>
      formalParameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: NullLiteral
          literal: null
        semicolon: ;
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: GenericFunctionType
                functionKeyword: Function
                typeParameters: TypeParameterList
                  leftBracket: <
                  typeParameters
                    TypeParameter
                      name: X
                  rightBracket: >
                parameters: FormalParameterList
                  leftParenthesis: (
                  rightParenthesis: )
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_gtEq() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T>=() => null;
//  ^
// [diag.unexpectedToken] Unexpected text '='.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: NullLiteral
          literal: null
        semicolon: ;
  declarations(v1)
    FunctionDeclaration
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
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_gtEq_invalidName_classTypeAlias() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<part T>=A with M;
//      ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    ClassTypeAlias2
      classKeyword: class
      name: C
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: <empty> <synthetic>
        rightBracket: >
      equals: =
      superclass: NamedType
        name: A
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: M
      body: SemicolonInstanceDeclarationBody
        semicolon: ;
  declarations(v1)
    ClassTypeAlias
      typedefKeyword: class
      name: C
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: <empty> <synthetic>
        rightBracket: >
      equals: =
      superclass: NamedType
        name: A
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: M
      semicolon: ;
''');
  }

  void test_typeParameters_gtEq_invalidName_nestedCloser_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<part <>= int;
//        ^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.builtInIdentifierAsType] The built-in identifier 'part' can't be used as a type.
//              ^^
// [diag.expectedTypeName] Expected a type name.
//              ^
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                 ^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    GenericTypeAlias2
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: <empty> <synthetic>
        rightBracket: > <synthetic>
      equals: = <synthetic>
      type: NamedType
        name: part
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: <empty> <synthetic>
          rightBracket: >
      semicolon: ; <synthetic>
    TopLevelVariablesDeclaration
      variables
        TopLevelVariable
          name: int
      semicolon: ;
  declarations(v1)
    GenericTypeAlias
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: <empty> <synthetic>
        rightBracket: > <synthetic>
      equals: = <synthetic>
      type: NamedType
        name: part
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: <empty> <synthetic>
          rightBracket: >
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ;
''');
  }

  void test_typeParameters_gtEq_invalidName_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F<part T>=int;
//        ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    GenericTypeAlias2
      typedefKeyword: typedef
      name: F
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: <empty> <synthetic>
        rightBracket: >
      equals: =
      type: NamedType
        name: int
      semicolon: ;
  declarations(v1)
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
      type: NamedType
        name: int
      semicolon: ;
''');
  }

  void test_typeParameters_gtGtEq() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T extends List<int>>=() => null;
//                    ^
// [diag.unexpectedToken] Unexpected text '='.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            extendsKeyword: extends
            bound: NamedType
              name: List
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: int
                rightBracket: >
        rightBracket: >
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: NullLiteral
          literal: null
        semicolon: ;
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                  rightBracket: >
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

  void test_typeParameters_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//^
// [diag.expectedToken] Expected to find '>'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: > <synthetic>
      formalParameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: NullLiteral
          literal: null
        semicolon: ;
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_outer_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T extends List<int>() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//                  ^
// [diag.expectedToken] Expected to find '>'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            extendsKeyword: extends
            bound: NamedType
              name: List
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: int
                rightBracket: >
        rightBracket: > <synthetic>
      formalParameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: NullLiteral
          literal: null
        semicolon: ;
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                  rightBracket: >
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }
}

/// Test how well the parser recovers when curly braces are mismatched.
@reflectiveTest
class BracesTest extends ParserDiagnosticsTest {
  void test_statement_if_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  if (x != null) {
}
// [diag.expectedToken][column 1][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          statements2
            IfStatement
              ifKeyword: if
              leftParenthesis: (
              expression2: BinaryOperatorInvocation
                leftOperand: ParsedUnqualifiedName
                  name: x
                operator: !=
                rightOperand: NullLiteral
                  literal: null
                binaryOperator: notEqual
              expression(v1): BinaryExpression
                leftOperand: SimpleIdentifier
                  token: x
                operator: !=
                rightOperand: NullLiteral
                  literal: null
              rightParenthesis: )
              thenStatement2: Block
                leftBracket: {
                rightBracket: } <synthetic>
          rightBracket: }
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: x
                  operator: !=
                  rightOperand: NullLiteral
                    literal: null
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_statement_if_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  if (x != null) {
  while (x == null) {}
}
// [diag.expectedToken][column 1][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          statements2
            IfStatement
              ifKeyword: if
              leftParenthesis: (
              expression2: BinaryOperatorInvocation
                leftOperand: ParsedUnqualifiedName
                  name: x
                operator: !=
                rightOperand: NullLiteral
                  literal: null
                binaryOperator: notEqual
              expression(v1): BinaryExpression
                leftOperand: SimpleIdentifier
                  token: x
                operator: !=
                rightOperand: NullLiteral
                  literal: null
              rightParenthesis: )
              thenStatement2: Block
                leftBracket: {
                statements2
                  WhileStatement
                    whileKeyword: while
                    leftParenthesis: (
                    condition2: BinaryOperatorInvocation
                      leftOperand: ParsedUnqualifiedName
                        name: x
                      operator: ==
                      rightOperand: NullLiteral
                        literal: null
                      binaryOperator: equal
                    condition(v1): BinaryExpression
                      leftOperand: SimpleIdentifier
                        token: x
                      operator: ==
                      rightOperand: NullLiteral
                        literal: null
                    rightParenthesis: )
                    body2: Block
                      leftBracket: {
                      rightBracket: }
                rightBracket: } <synthetic>
          rightBracket: }
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: x
                  operator: !=
                  rightOperand: NullLiteral
                    literal: null
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  statements
                    WhileStatement
                      whileKeyword: while
                      leftParenthesis: (
                      condition: BinaryExpression
                        leftOperand: SimpleIdentifier
                          token: x
                        operator: ==
                        rightOperand: NullLiteral
                          literal: null
                      rightParenthesis: )
                      body: Block
                        leftBracket: {
                        rightBracket: }
                  rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_unit_functionBody_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
class C {}
// [diag.expectedIdentifierButGotKeyword][column 1][length 5] 'class' can't be used as an identifier because it's a keyword.
// [diag.expectedToken][column 1][length 5] Expected to find ';'.
// [diag.missingStatement][column 1][length 5] Expected a statement.
//    ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 11][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          statements2
            ExpressionStatement
              expression2: ParsedUnqualifiedName
                name: class
              expression(v1): SimpleIdentifier
                token: class
              semicolon: ; <synthetic>
            ExpressionStatement
              expression2: ParsedUnqualifiedName
                name: C
              expression(v1): SimpleIdentifier
                token: C
              semicolon: ; <synthetic>
            Block
              leftBracket: {
              rightBracket: }
          rightBracket: } <synthetic>
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: class
                semicolon: ; <synthetic>
              ExpressionStatement
                expression: SimpleIdentifier
                  token: C
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_unit_functionBody_function() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
g(y) => y;
// [diag.expectedToken][column 11][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          statements2
            LocalFunctionDeclaration
              name: g
              formalParameters: FormalParameterList
                leftParenthesis: (
                requiredPositionalFormalParameters
                  RegularFormalParameter
                    name: y
                rightParenthesis: )
              body: ExpressionFunctionBody
                functionDefinition: =>
                expression2: ParsedUnqualifiedName
                  name: y
                expression(v1): SimpleIdentifier
                  token: y
                semicolon: ;
          statements(v1)
            FunctionDeclarationStatement
              functionDeclaration: FunctionDeclaration
                name: g
                functionExpression: FunctionExpression
                  parameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: y
                    rightParenthesis: )
                  body: ExpressionFunctionBody
                    functionDefinition: =>
                    expression: SimpleIdentifier
                      token: y
                    semicolon: ;
          rightBracket: } <synthetic>
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
                  name: g
                  functionExpression: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: y
                      rightParenthesis: )
                    body: ExpressionFunctionBody
                      functionDefinition: =>
                      expression: SimpleIdentifier
                        token: y
                      semicolon: ;
            rightBracket: } <synthetic>
''');
  }

  void test_unit_functionBody_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
// [diag.expectedToken][column 7][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: } <synthetic>
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: } <synthetic>
''');
  }

  void test_unit_functionBody_variable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
int y = 0;
// [diag.expectedToken][column 11][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          statements2
            LocalVariablesDeclarationStatement
              declaration: LocalVariablesDeclaration
                type: NamedType
                  name: int
                variables
                  LocalVariable
                    name: y
                    equals: =
                    initializer: IntegerLiteral
                      literal: 0
              semicolon: ;
          statements(v1)
            VariableDeclarationStatement
              variables: VariableDeclarationList
                type: NamedType
                  name: int
                variables
                  VariableDeclaration
                    name: y
                    equals: =
                    initializer: IntegerLiteral
                      literal: 0
              semicolon: ;
          rightBracket: } <synthetic>
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: y
                      equals: =
                      initializer: IntegerLiteral
                        literal: 0
                semicolon: ;
            rightBracket: } <synthetic>
''');
  }
}

/// Test how well the parser recovers when square brackets are mismatched.
@reflectiveTest
class BracketsTest extends ParserDiagnosticsTest {
  void test_indexOperator() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) => l[x
//        ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 12][length 1] Expected to find ']'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: ReceiverIndexExpression
          receiver: ParsedUnqualifiedName
            name: l
          leftBracket: [
          index: ParsedUnqualifiedName
            name: x
          rightBracket: ] <synthetic>
        expression(v1): IndexExpression
          target: SimpleIdentifier
            token: l
          leftBracket: [
          index: SimpleIdentifier
            token: x
          rightBracket: ] <synthetic>
        semicolon: ; <synthetic>
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IndexExpression
            target: SimpleIdentifier
              token: l
            leftBracket: [
            index: SimpleIdentifier
              token: x
            rightBracket: ] <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_indexOperator_nullAware() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) => l?[x
//         ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 13][length 1] Expected to find ']'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression2: ReceiverIndexExpression
          receiver: ParsedUnqualifiedName
            name: l
          question: ?
          leftBracket: [
          index: ParsedUnqualifiedName
            name: x
          rightBracket: ] <synthetic>
        expression(v1): IndexExpression
          target: SimpleIdentifier
            token: l
          question: ?
          leftBracket: [
          index: SimpleIdentifier
            token: x
          rightBracket: ] <synthetic>
        semicolon: ; <synthetic>
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IndexExpression
            target: SimpleIdentifier
              token: l
            question: ?
            leftBracket: [
            index: SimpleIdentifier
              token: x
            rightBracket: ] <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_listLiteral_inner_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [[0], [1];
//               ^
// [diag.expectedToken] Expected to find ']'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      constFinalOrVarKeyword: var
      variables
        TopLevelVariable
          name: x
          equals: =
          initializer: ListLiteral
            leftBracket: [
            elements2
              ListLiteral
                leftBracket: [
                elements2
                  IntegerLiteral
                    literal: 0
                rightBracket: ]
              ListLiteral
                leftBracket: [
                elements2
                  IntegerLiteral
                    literal: 1
                rightBracket: ]
            rightBracket: ] <synthetic>
      semicolon: ;
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                ListLiteral
                  leftBracket: [
                  elements
                    IntegerLiteral
                      literal: 0
                  rightBracket: ]
                ListLiteral
                  leftBracket: [
                  elements
                    IntegerLiteral
                      literal: 1
                  rightBracket: ]
              rightBracket: ] <synthetic>
      semicolon: ;
''');
  }

  void test_listLiteral_inner_notLast() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [[0], [1, [2]];
//                    ^
// [diag.expectedToken] Expected to find ']'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      constFinalOrVarKeyword: var
      variables
        TopLevelVariable
          name: x
          equals: =
          initializer: ListLiteral
            leftBracket: [
            elements2
              ListLiteral
                leftBracket: [
                elements2
                  IntegerLiteral
                    literal: 0
                rightBracket: ]
              ListLiteral
                leftBracket: [
                elements2
                  IntegerLiteral
                    literal: 1
                  ListLiteral
                    leftBracket: [
                    elements2
                      IntegerLiteral
                        literal: 2
                    rightBracket: ]
                rightBracket: ]
            rightBracket: ] <synthetic>
      semicolon: ;
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                ListLiteral
                  leftBracket: [
                  elements
                    IntegerLiteral
                      literal: 0
                  rightBracket: ]
                ListLiteral
                  leftBracket: [
                  elements
                    IntegerLiteral
                      literal: 1
                    ListLiteral
                      leftBracket: [
                      elements
                        IntegerLiteral
                          literal: 2
                      rightBracket: ]
                  rightBracket: ]
              rightBracket: ] <synthetic>
      semicolon: ;
''');
  }

  void test_listLiteral_missing_comma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [0 1];
//         ^
// [diag.expectedToken] Expected to find ','.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      constFinalOrVarKeyword: var
      variables
        TopLevelVariable
          name: x
          equals: =
          initializer: ListLiteral
            leftBracket: [
            elements2
              IntegerLiteral
                literal: 0
              IntegerLiteral
                literal: 1
            rightBracket: ]
      semicolon: ;
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                IntegerLiteral
                  literal: 0
                IntegerLiteral
                  literal: 1
              rightBracket: ]
      semicolon: ;
''');
  }

  void test_listLiteral_outer_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [0, 1
//          ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 14][length 1] Expected to find ']'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelVariablesDeclaration
      constFinalOrVarKeyword: var
      variables
        TopLevelVariable
          name: x
          equals: =
          initializer: ListLiteral
            leftBracket: [
            elements2
              IntegerLiteral
                literal: 0
              IntegerLiteral
                literal: 1
            rightBracket: ] <synthetic>
      semicolon: ; <synthetic>
  declarations(v1)
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                IntegerLiteral
                  literal: 0
                IntegerLiteral
                  literal: 1
              rightBracket: ] <synthetic>
      semicolon: ; <synthetic>
''');
  }
}

/// Test how well the parser recovers when parentheses are mismatched.
@reflectiveTest
class ParenthesesTest extends ParserDiagnosticsTest {
  void test_if_last() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  if (x
//    ^
// [diag.expectedToken] Expected to find ';'.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
// [diag.expectedToken][column 1][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          statements2
            IfStatement
              ifKeyword: if
              leftParenthesis: (
              expression2: ParsedUnqualifiedName
                name: x
              expression(v1): SimpleIdentifier
                token: x
              rightParenthesis: ) <synthetic>
              thenStatement2: ExpressionStatement
                expression2: ParsedUnqualifiedName
                  name: <empty> <synthetic>
                expression(v1): SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
          rightBracket: }
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  if (x
  while(x != null) {}
//^
// [diag.expectedToken] Expected to find ')'.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          statements2
            IfStatement
              ifKeyword: if
              leftParenthesis: (
              expression2: ParsedUnqualifiedName
                name: x
              expression(v1): SimpleIdentifier
                token: x
              rightParenthesis: ) <synthetic>
              thenStatement2: WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition2: BinaryOperatorInvocation
                  leftOperand: ParsedUnqualifiedName
                    name: x
                  operator: !=
                  rightOperand: NullLiteral
                    literal: null
                  binaryOperator: notEqual
                condition(v1): BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: x
                  operator: !=
                  rightOperand: NullLiteral
                    literal: null
                rightParenthesis: )
                body2: Block
                  leftBracket: {
                  rightBracket: }
          rightBracket: }
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: ) <synthetic>
                thenStatement: WhileStatement
                  whileKeyword: while
                  leftParenthesis: (
                  condition: BinaryExpression
                    leftOperand: SimpleIdentifier
                      token: x
                    operator: !=
                    rightOperand: NullLiteral
                      literal: null
                  rightParenthesis: )
                  body: Block
                    leftBracket: {
                    rightBracket: }
            rightBracket: }
''');
  }

  void test_parameterList_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x
class C {}
// [diag.missingFunctionBody][column 1][length 5] A function body must be provided.
// [diag.expectedToken][column 1][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: ) <synthetic>
      body: BlockFunctionBody
        block: Block
          leftBracket: { <synthetic>
          rightBracket: } <synthetic>
    ClassDeclaration2
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockInstanceDeclarationBody
        leftBracket: {
        rightBracket: }
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parameterList_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x
// ^
// [diag.missingFunctionBody][column 4][length 0] A function body must be provided.
// [diag.expectedToken][column 4][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations2
    TopLevelFunctionDeclaration
      name: f
      formalParameters: FormalParameterList
        leftParenthesis: (
        requiredPositionalFormalParameters
          RegularFormalParameter
            name: x
        rightParenthesis: ) <synthetic>
      body: BlockFunctionBody
        block: Block
          leftBracket: { <synthetic>
          rightBracket: } <synthetic>
  declarations(v1)
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
''');
  }
}
