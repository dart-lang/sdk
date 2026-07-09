// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import 'parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypedParameterVarTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionTypedParameterVarTest extends ParserDiagnosticsTest {
  test_superFormalParameter_var_functionTyped() async {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {
  A(var super.a<T>());
//  ^^^
// [diag.functionTypedParameterVar] Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.
}
''');

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  constFinalOrVarKeyword: var
  superKeyword: super
  period: .
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }
}
