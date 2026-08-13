// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DotShorthandParserTest extends ParserDiagnosticsTest {
  void test_invocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {}

void main() {
  C c = .new();
}
''');

    var node = parseResult.findNode.singleDotShorthandInvocation;
    assertParsedNodeText(node, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
''');
  }

  void test_propertyAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E { a }

void main() {
  E e = .a;
}
''');

    var node = parseResult.findNode.singleDotShorthandPropertyAccess;
    assertParsedNodeText(node, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: a
  isDotShorthand: true
''');
  }
}
