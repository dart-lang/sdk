// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableParserTest);
  });
}

@reflectiveTest
class TopLevelVariableParserTest extends ParserDiagnosticsTest {
  test_abstract() {
    var parseResult = parseStringWithErrors(r'''
abstract int foo;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  abstractKeyword: abstract
  variables: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: foo
  semicolon: ;
''');
  }

  test_abstract_language305() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
abstract int foo;
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 15, 8)]);

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  abstractKeyword: abstract
  variables: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: foo
  semicolon: ;
''');
  }

  test_augment() {
    var parseResult = parseStringWithErrors(r'''
augment final foo = 0;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  augmentKeyword: augment
  variables: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: foo
        equals: =
        initializer: IntegerLiteral
          literal: 0
  semicolon: ;
''');
  }

  test_augment_abstract() {
    var parseResult = parseStringWithErrors(r'''
augment abstract int foo;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  augmentKeyword: augment
  abstractKeyword: abstract
  variables: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: foo
  semicolon: ;
''');
  }

  test_augment_abstract_language305() {
    var parseResult = parseStringWithErrors('''
// @dart = 3.5
augment abstract int foo;
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 8)]);

    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: augment
        variables
          VariableDeclaration
            name: abstract
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: foo
      semicolon: ;
''');
  }

  test_augment_language305() {
    var parseResult = parseStringWithErrors('''
// @dart = 3.5
augment final foo = 0;
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 15, 7),
      error(diag.expectedToken, 15, 7),
    ]);

    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: augment
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: foo
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  test_external() {
    var parseResult = parseStringWithErrors(r'''
external int foo;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  externalKeyword: external
  variables: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: foo
  semicolon: ;
''');
  }
}
