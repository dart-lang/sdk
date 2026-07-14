// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer_testing/src/expected_diagnostics.dart'
    as expected_diagnostics;
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

import '../../util/diff.dart';
import '../../util/element_printer.dart';
import '../../util/feature_sets.dart';
import '../dart/resolution/node_text_expectations.dart';
import '../summary/resolved_ast_printer.dart';

class ParserDiagnosticsTest {
  FeatureSet get testFeatureSet => FeatureSets.latestWithExperiments;

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
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  /// Parses [content] without checking diagnostics.
  ///
  /// Use this only for parser smoke tests where diagnostics are intentionally
  /// irrelevant, for example when verifying that a broad set of inputs does not
  /// crash or loop.
  ParseStringResult parseTestCodeIgnoringDiagnostics(
    String content, {
    FeatureSet? featureSet,
  }) {
    return parseString(
      content: content,
      featureSet: featureSet ?? testFeatureSet,
      throwIfDiagnostics: false,
    );
  }

  /// Parses [content] and checks that its inline diagnostic markers match the
  /// diagnostics. Marker lines are test metadata and are removed before
  /// parsing, so they cannot influence parser recovery.
  ParseStringResult parseTestCodeWithDiagnostics(
    String content, {
    FeatureSet? featureSet,
  }) {
    var cleanContent = expected_diagnostics.removeDiagnosticExpectations(
      content,
    );
    var parseContent = expected_diagnostics.removeTrailingLineTerminator(
      cleanContent,
    );
    var result = parseString(
      content: parseContent,
      featureSet: featureSet ?? testFeatureSet,
      throwIfDiagnostics: false,
    );

    var actual = expected_diagnostics.updateExpectedDiagnostics(
      content: cleanContent,
      actualDiagnostics: result.errors,
    );
    if (actual != content) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(content, actual);
      }
      fail('See the difference above.');
    }

    return result;
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
    ResolvedAstPrinter(
      sink: sink,
      elementPrinter: elementPrinter,
      configuration: ResolvedNodeTextConfiguration()
        ..withTokenPreviousNext = withTokenPreviousNext,
      withResolution: false,
      withOffsets: withOffsets,
    ).writeNode(node);
    return buffer.toString();
  }
}

extension ParseStringResultExtension on ParseStringResult {
  FindNode get findNode {
    return FindNode(content, unit);
  }
}
