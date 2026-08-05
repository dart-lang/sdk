// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/feature_sets.dart';
import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordLiteralParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecordLiteralParserTest extends ParserDiagnosticsTest {
  void test_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (0, a: 1);
''');

    var node = parseResult.findNode.singleRecordLiteral;
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
    RecordLiteralNamedField
      name: a
      colon: :
      fieldExpression: IntegerLiteral
        literal: 1
  rightParenthesis: )
''');
  }

  void test_named_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (0, a: 1,);
''');

    var node = parseResult.findNode.singleRecordLiteral;
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
    RecordLiteralNamedField
      name: a
      colon: :
      fieldExpression: IntegerLiteral
        literal: 1
  rightParenthesis: )
''');
  }

  void test_namedFieldRecovery_language219() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (a: 0);
//        ^
// [diag.experimentNotEnabled] This requires the 'records' language feature to be enabled.
''', featureSet: FeatureSets.language_2_19);

    var node = parseResult.findNode.singleParenthesizedExpression;
    assertParsedNodeText(node, r'''
ParenthesizedExpression
  leftParenthesis: (
  expression: IntegerLiteral
    literal: 0
  rightParenthesis: )
''');
  }

  void test_positional_one_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (0,);
''');

    var node = parseResult.findNode.singleRecordLiteral;
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
  rightParenthesis: )
''');
  }

  void test_positional_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (0, 1,);
''');

    var node = parseResult.findNode.singleRecordLiteral;
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
    IntegerLiteral
      literal: 1
  rightParenthesis: )
''');
  }
}
