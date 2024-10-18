// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAliasParserTest);
  });
}

@reflectiveTest
class TypeAliasParserTest extends ParserDiagnosticsTest {
  test_legacy_augment() {
    var parseResult = parseStringWithErrors(r'''
augment typedef void A();
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFunctionTypeAlias;
    assertParsedNodeText(node, r'''
FunctionTypeAlias
  augmentKeyword: augment
  typedefKeyword: typedef
  returnType: NamedType
    name: void
  name: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  semicolon: ;
''');
  }

  test_modern_augment() {
    var parseResult = parseStringWithErrors(r'''
augment typedef A = int;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleGenericTypeAlias;
    assertParsedNodeText(node, r'''
GenericTypeAlias
  augmentKeyword: augment
  typedefKeyword: typedef
  name: A
  equals: =
  type: NamedType
    name: int
''');
  }

  test_modern_missingName() {
    // Does not look good.
    // https://github.com/dart-lang/sdk/issues/56912
    var parseResult = parseStringWithErrors(r'''
typedef = int;
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 0, 7),
      error(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
      error(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, 8, 1),
      error(ParserErrorCode.EXPECTED_EXECUTABLE, 8, 1),
      error(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 10, 3),
    ]);

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ;
''');
  }
}
