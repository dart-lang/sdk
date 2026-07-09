// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TopLevelVariableParserTest extends ParserDiagnosticsTest {
  test_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract int foo;
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
abstract int foo;
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment final foo = 0;
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment abstract int foo;
''');

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
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
augment abstract int foo;
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');

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

  test_augment_external() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment external int foo;
''');

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  augmentKeyword: augment
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

  test_augment_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
augment final foo = 0;
// [diag.missingConstFinalVarOrType][column 1][length 7] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
external int foo;
''');

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
