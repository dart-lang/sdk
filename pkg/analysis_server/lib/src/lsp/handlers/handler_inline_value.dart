// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide MessageType;
import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/extensions/positions.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/element/extensions.dart';

typedef StaticOptions =
    Either3<bool, InlineValueOptions, InlineValueRegistrationOptions>;

class InlineValueHandler
    extends
        SharedMessageHandler<InlineValueParams, TextDocumentInlineValueResult> {
  InlineValueHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_inlineValue;

  @override
  LspJsonHandler<InlineValueParams> get jsonHandler =>
      InlineValueParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<TextDocumentInlineValueResult>> handle(
    InlineValueParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var filePath = pathOfDoc(params.textDocument);
    return filePath.mapResult((filePath) async {
      var unitResult = await server.getResolvedUnit(filePath);
      if (unitResult == null) {
        return success(null);
      }
      var lineInfo = unitResult.lineInfo;

      // We will provide values from the start of the visible range up to
      // the end of the line the debugger is stopped on (which will do by just
      // jumping to position 0 of the next line).
      var visibleRange = params.range;
      var stoppedLocation = params.context.stoppedLocation;
      var applicableRange = Range(
        start: visibleRange.start,
        end: Position(line: stoppedLocation.end.line + 1, character: 0),
      );

      var stoppedOffset = toOffset(lineInfo, stoppedLocation.end);
      return stoppedOffset.mapResult((stoppedOffset) async {
        // Find the function that is executing. We will only show values for
        // this single function expression.
        var node = await server.getNodeAtOffset(filePath, stoppedOffset);
        var function = node?.thisOrAncestorOfType<FunctionExpression>();
        if (function == null) {
          return success(null);
        }

        var collector = _InlineValueCollector(lineInfo, applicableRange);
        var visitor = _InlineValueVisitor(collector, function);
        function.accept(visitor);

        return success(collector.values.values.toList());
      });
    });
  }
}

class InlineValueRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  InlineValueRegistrations(super.info);

  @override
  ToJsonable? get options =>
      TextDocumentRegistrationOptions(documentSelector: dartFiles);

  @override
  Method get registrationMethod => Method.textDocument_inlineValue;

  @override
  StaticOptions get staticOptions => Either3.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.inlineValue;
}

/// Collects inline values, keeping only the most relevant where an element
/// is recorded multiple times.
class _InlineValueCollector {
  /// A map of elements and their inline value.
  final Map<Element2, InlineValue> values = {};

  /// The range for which inline values should be retained.
  ///
  /// This should be approximately the range of the visible code on screen up to
  /// the point of execution.
  final Range applicableRange;

  /// A [LineInfo] used to convert offsets to lines/columns for comparing to
  /// [applicableRange].
  final LineInfo lineInfo;

  _InlineValueCollector(this.lineInfo, this.applicableRange);

  /// Records a variable inline value for [element] with [offset]/[length].
  ///
  /// Variable inline values are sent to the client without expressions/names
  /// because the client can infer the name from the range and look it up from
  /// the debuggers Scopes/Variables.
  void recordVariableLookup(Element2? element, int offset, int length) {
    if (element == null || element.isWildcardVariable) return;

    assert(offset >= 0);
    assert(length > 0);

    var range = toRange(lineInfo, offset, length);

    // Never record anything outside of the visible range.
    if (!range.intersects(applicableRange)) {
      return;
    }

    // We only want to show each variable once, so keep only the one furthest
    // into the source (closest to the execution pointer).
    var existingPosition = values[element]?.map(
      (expression) => expression.range.start,
      (text) => text.range.start,
      (variable) => variable.range.start,
    );
    if (existingPosition != null &&
        existingPosition.isAfterOrEqual(range.start)) {
      return;
    }

    values[element] = InlineValue.t3(
      InlineValueVariableLookup(
        caseSensitiveLookup: true,
        range: range,
        // We don't provide name, because it always matches the source code
        // for a variable and can be inferred.
      ),
    );
  }
}

/// Visits a function expression and reports nodes that should have inline
/// values to [collector].
class _InlineValueVisitor extends GeneralizingAstVisitor<void> {
  final _InlineValueCollector collector;
  final FunctionExpression rootFunction;

  _InlineValueVisitor(this.collector, this.rootFunction);

  @override
  void visitFormalParameter(FormalParameter node) {
    var name = node.name;
    if (name != null) {
      collector.recordVariableLookup(
        node.declaredFragment?.element,
        name.offset,
        name.length,
      );
    }
    super.visitFormalParameter(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Don't descend into nested functions.
    if (node != rootFunction) {
      return;
    }

    super.visitFunctionExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    switch (node.element) {
      case LocalVariableElement2(name3: _?):
      case FormalParameterElement():
        collector.recordVariableLookup(node.element, node.offset, node.length);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var name = node.name;
    collector.recordVariableLookup(
      node.declaredElement2,
      name.offset,
      name.length,
    );
    super.visitVariableDeclaration(node);
  }
}
