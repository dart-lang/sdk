// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullAwareElementsParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullAwareElementsParserTest extends ParserDiagnosticsTest {
  test_simple_list_literal() {
    var parserResult = parseTestCodeWithDiagnostics(r'''
f(int? x) => [?x];
''');

    var node = parserResult.findNode.singleNullAwareElement;
    assertParsedNodeText(node, r'''
NullAwareElement
  question: ?
  value: SimpleIdentifier
    token: x
''');
  }

  test_simple_map_literal_both_null_aware() {
    var parserResult = parseTestCodeWithDiagnostics(r'''
f(int? x, String? y) => {?x: ?y};
''');

    var node = parserResult.findNode.mapLiteralEntry('?x: ?y');
    assertParsedNodeText(node, r'''
MapLiteralEntry
  keyQuestion: ?
  key: SimpleIdentifier
    token: x
  separator: :
  valueQuestion: ?
  value: SimpleIdentifier
    token: y
''');
  }

  test_simple_map_literal_null_aware_key() {
    var parserResult = parseTestCodeWithDiagnostics(r'''
f(num? x, bool y) => {?x: y};
''');

    var node = parserResult.findNode.mapLiteralEntry("?x: y");
    assertParsedNodeText(node, r'''
MapLiteralEntry
  keyQuestion: ?
  key: SimpleIdentifier
    token: x
  separator: :
  value: SimpleIdentifier
    token: y
''');
  }

  test_simple_map_literal_null_aware_value() {
    var parserResult = parseTestCodeWithDiagnostics(r'''
f(String x, double? y) => {x: ?y};
''');

    var node = parserResult.findNode.mapLiteralEntry("x: ?y");
    assertParsedNodeText(node, r'''
MapLiteralEntry
  key: SimpleIdentifier
    token: x
  separator: :
  valueQuestion: ?
  value: SimpleIdentifier
    token: y
''');
  }

  test_simple_set_literal() {
    var parserResult = parseTestCodeWithDiagnostics(r'''
f(String? x) => {?x};
''');

    var node = parserResult.findNode.singleNullAwareElement;
    assertParsedNodeText(node, r'''
NullAwareElement
  question: ?
  value: SimpleIdentifier
    token: x
''');
  }
}
