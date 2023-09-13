// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationParserTest);
  });
}

@reflectiveTest
class ClassDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment_constructor_named() {
    final parseResult = parseStringWithErrors(r'''
library augment 'a.dart';
augment class A {
  augment A.named();
}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  name: A
  leftBracket: {
  members
    ConstructorDeclaration
      augmentKeyword: augment
      returnType: SimpleIdentifier
        token: A
      period: .
      name: named
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: EmptyFunctionBody
        semicolon: ;
  rightBracket: }
''');
  }
}
