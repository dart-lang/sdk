// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclarationParserTest);
  });
}

@reflectiveTest
class MixinDeclarationParserTest extends ParserDiagnosticsTest {
  test_constructor_named() {
    final parseResult = parseStringWithErrors(r'''
mixin A {
  A.named();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 12, 1),
    ]);

    // Mixins cannot have constructors.
    // So, we don't put them into AST at all.
    final node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: A
  leftBracket: {
  rightBracket: }
''');
  }
}
