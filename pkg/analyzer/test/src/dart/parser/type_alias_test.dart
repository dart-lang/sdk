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
  semicolon: ;
''');
  }

  test_modern_missingName() {
    // Does not look good.
    // https://github.com/dart-lang/sdk/issues/56912
    var parseResult = parseStringWithErrors(r'''
typedef = int;
''');
    parseResult.assertErrors([error(ParserErrorCode.missingIdentifier, 8, 1)]);

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
        name: int
      semicolon: ;
''');
  }
}
