// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ParameterTest extends ParserDiagnosticsTest {
  void test_required_functionType_noIdentifier_eof() {
    var parseResult = parseStringWithErrors(r'''
f(Function(void)) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: FunctionTypedFormalParameter
            name: Function
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: SimpleFormalParameter
                type: NamedType
                  name: void
                name: <empty> <synthetic>
              rightParenthesis: )
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_required_typeArgument_noGt_eof() {
    var parseResult = parseStringWithErrors(r'''
          class C<E> {}
          f(C<int Function(int, int) c) {}
          
''');
    parseResult.assertErrors([error(diag.expectedToken, 37, 1)]);
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
              name: E
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: C
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }
}
