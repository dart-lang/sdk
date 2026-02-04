// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

import '../../generated/test_support.dart';
import '../../util/diff.dart';
import '../../util/element_printer.dart';
import '../../util/feature_sets.dart';
import '../dart/resolution/node_text_expectations.dart';
import '../summary/resolved_ast_printer.dart';

class ParserDiagnosticsTest {
  // TODO(scheglov): Enable [withCheckingLinking] everywhere.
  void assertParsedNodeText(
    AstNode node,
    String expected, {
    bool withOffsets = false,
    bool withTokenPreviousNext = false,
  }) {
    var actual = _parsedNodeText(
      node,
      withOffsets: withOffsets,
      withTokenPreviousNext: withTokenPreviousNext,
    );
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      printPrettyDiff(expected, actual);
      fail('See the difference above.');
    }
  }

  ExpectedError error(
    DiagnosticCode code,
    int offset,
    int length, {
    Pattern? correctionContains,
    // TODO(FMorschel): refactor the uses of this to prefer `messageContains`
    String? text,
    List<Pattern> messageContains = const [],
    List<ExpectedContextMessage> contextMessages = const [],
  }) {
    assert(
      text == null || messageContains.isEmpty,
      'Only use one of text or messageContains',
    );
    return ExpectedError(
      code,
      offset,
      length,
      correctionContains: correctionContains,
      messageContainsAll: text != null ? [text] : messageContains,
      contextMessages: contextMessages,
    );
  }

  ParseStringResult parseStringWithErrors(String content) {
    return parseString(
      content: content,
      featureSet: FeatureSets.latestWithExperiments,
      throwIfDiagnostics: false,
    );
  }

  String _parsedNodeText(
    AstNode node, {
    required bool withOffsets,
    required bool withTokenPreviousNext,
  }) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );
    node.accept(
      ResolvedAstPrinter(
        sink: sink,
        elementPrinter: elementPrinter,
        configuration: ResolvedNodeTextConfiguration()
          ..withTokenPreviousNext = withTokenPreviousNext,
        withResolution: false,
        withOffsets: withOffsets,
      ),
    );
    return buffer.toString();
  }
}

extension ParseStringResultExtension on ParseStringResult {
  FindNode get findNode {
    return FindNode(content, unit);
  }

  void assertErrors(List<ExpectedDiagnostic> expectedDiagnostics) {
    var diagnosticListener = GatheringDiagnosticListener();
    diagnosticListener.addAll(errors);
    diagnosticListener.assertErrors(expectedDiagnostics);
  }

  void assertNoErrors() {
    assertErrors(const []);
  }
}
