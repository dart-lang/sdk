// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide MessageType;
import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/client_configuration.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/extensions/positions.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/services/correction/dart/convert_null_check_to_null_aware_element_or_entry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/dart/element/type.dart';
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

      // Compute the ranges for which we will provide values. We produce two
      // ranges here because for some kinds of variables (simple values) it's
      // convenient to see them on an `if` statement on the same line that
      // hasn't executed yet. However, we should avoid evaluating getters which
      // may have side effects if they haven't executed previously, because this
      // may change state in a way that's less obvious.
      var visibleRange = params.range;
      var stoppedLocation = params.context.stoppedLocation;
      var rangeAlreadyExecuted = Range(
        start: visibleRange.start,
        end: stoppedLocation.end,
      );
      var rangeIncludingCurrentLine = Range(
        start: visibleRange.start,
        end: Position(line: stoppedLocation.end.line + 1, character: 0),
      );

      var stoppedOffset = toOffset(lineInfo, stoppedLocation.end);
      return stoppedOffset.mapResult((stoppedOffset) async {
        // Find the function that is executing. We will only show values for
        // this single function expression.
        var node = unitResult.unit.nodeCovering(offset: stoppedOffset);
        var function = node?.thisOrAncestorMatching(
          (node) => node is FunctionExpression || node is MethodDeclaration,
        );
        if (function == null) {
          return success(null);
        }

        var collector = _InlineValueCollector(
          lineInfo,
          rangeAlreadyExecuted: rangeAlreadyExecuted,
          rangeIncludingCurrentLine: rangeIncludingCurrentLine,
        );
        var visitor = _InlineValueVisitor(
          server.lspClientConfiguration,
          collector,
          function,
          stoppedOffset,
        );
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
  final Map<analyzer.Element, InlineValue> values = {};

  /// The range for which simple inline values should be returned.
  ///
  /// This should be approximately the range of the visible code on screen up to
  /// the point of execution and including the current line.
  final Range rangeIncludingCurrentLine;

  /// The range for which complex inline values (such as getters) should be
  /// returned.
  ///
  /// This should be approximately the range of the visible code on screen up to
  /// the point of execution.
  final Range rangeAlreadyExecuted;

  /// A [LineInfo] used to convert offsets to lines/columns for comparing to
  /// locations provided by the client.
  final LineInfo lineInfo;

  _InlineValueCollector(
    this.lineInfo, {
    required this.rangeAlreadyExecuted,
    required this.rangeIncludingCurrentLine,
  });

  /// Records an expression inline value for [element] with [offset]/[length].
  ///
  /// Expression values are sent to the client without expressions because the
  /// client can use the range from the source to get the expression.
  void recordExpression(analyzer.Element? element, int offset, int length) {
    assert(offset >= 0);
    assert(length > 0);
    if (element == null) return;

    var range = toRange(lineInfo, offset, length);

    // Don't record anything outside of the visible range (excluding next line).
    if (!range.intersects(rangeAlreadyExecuted)) {
      return;
    }

    var value = InlineValue.t1(
      InlineValueEvaluatableExpression(
        range: range,
        // We don't provide expression, because it always matches the source
        // code and can be inferred.
      ),
    );
    _record(value, element);
  }

  /// Records a variable inline value for [element] with [offset]/[length].
  ///
  /// Variable inline values are sent to the client without names because the
  /// client can infer the name from the range and look it up from the debuggers
  /// Scopes/Variables.
  void recordVariableLookup(analyzer.Element? element, int offset, int length) {
    assert(offset >= 0);
    assert(length > 0);
    if (element == null || element.isWildcardVariable) return;

    var range = toRange(lineInfo, offset, length);

    // Don't record anything outside of the visible range (including next line).
    if (!range.intersects(rangeIncludingCurrentLine)) {
      return;
    }

    var value = InlineValue.t3(
      InlineValueVariableLookup(
        caseSensitiveLookup: true,
        range: range,
        // We don't provide name, because it always matches the source code
        // for a variable and can be inferred.
      ),
    );
    _record(value, element);
  }

  /// Extracts the range from an [InlineValue].
  Range _getRange(InlineValue value) {
    return value.map(
      (expression) => expression.range,
      (text) => text.range,
      (variable) => variable.range,
    );
  }

  /// Returns whether [element] is something that should never be eagerly
  /// evaluated because of potential side-effects (such as `iterable.length`).
  bool _isExcludedElement(analyzer.Element element) {
    return switch (element) {
      analyzer.VariableElement() => _isExcludedType(element.type),
      analyzer.GetterElement() => _isExcludedType(element.returnType),
      _ => false,
    };
  }

  /// Returns whether [type] is something that should never be eagerly
  /// evaluated because of potential side-effects (such as `iterable.length`).
  bool _isExcludedType(DartType? type) {
    if (type == null) {
      return false;
    }
    return type.isDartCoreIterable ||
        type.isDartAsyncFuture ||
        type.isDartAsyncFutureOr ||
        type.isDartAsyncStream;
  }

  /// Records an inline value [value] for [element] if it is within range and is
  /// the latest one in the source for that element.
  void _record(InlineValue value, analyzer.Element element) {
    // Don't create values for any elements that are excluded types.
    if (_isExcludedElement(element)) {
      return;
    }

    var range = _getRange(value);

    // We only want to show each variable once, so keep only the one furthest
    // into the source (closest to the execution pointer).
    if (values[element] case var existingValue?) {
      var existingPosition = _getRange(existingValue).start;
      if (existingPosition.isAfterOrEqual(range.start)) {
        return;
      }
    }

    values[element] = value;
  }
}

/// Visits a function expression and reports nodes that should have inline
/// values to [collector].
class _InlineValueVisitor extends GeneralizingAstVisitor<void> {
  final LspClientConfiguration clientConfiguration;
  final _InlineValueCollector collector;
  final AstNode rootNode;

  /// The offset where execution currently is.
  ///
  /// This is used to determine which block of code we're inside, so we can
  /// avoid showing inline values in other branches.
  final int currentExecutionOffset;

  _InlineValueVisitor(
    this.clientConfiguration,
    this.collector,
    this.rootNode,
    this.currentExecutionOffset,
  );

  bool get experimentalInlineValuesProperties =>
      clientConfiguration.global.experimentalInlineValuesProperties;

  @override
  void visitBlock(Block node) {
    if (currentExecutionOffset < node.offset ||
        currentExecutionOffset > node.end) {
      return;
    }

    super.visitBlock(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    var name = node.name;
    collector.recordVariableLookup(
      node.declaredElement2,
      name.offset,
      name.length,
    );
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var name = node.name;
    collector.recordVariableLookup(
      node.declaredElement2,
      name.offset,
      name.length,
    );
    super.visitDeclaredVariablePattern(node);
  }

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
    if (node != rootNode) {
      return;
    }

    super.visitFunctionExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (experimentalInlineValuesProperties) {
      // Don't create values for excluded types or access of their properties.
      if (collector._isExcludedType(node.prefix.staticType)) {
        return;
      }

      var parent = node.parent;

      // Never produce values for the left side of a property access.
      var isTarget = parent is PropertyAccess && node == parent.realTarget;

      // Never produce values for obvious enum getters (this includes `values`).
      var isEnumGetter =
          node.element is analyzer.GetterElement &&
          node.element?.enclosingElement is analyzer.EnumElement;

      if (!isTarget && !isEnumGetter) {
        collector.recordExpression(node.element, node.offset, node.length);
      }
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var target = node.target;
    if (experimentalInlineValuesProperties && target is Identifier) {
      // Don't create values for excluded types or access of their properties.
      if (collector._isExcludedType(target.staticType)) {
        return;
      }

      collector.recordExpression(
        node.canonicalElement,
        node.offset,
        node.length,
      );
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var parent = node.parent;

    // Never produce values for the left side of a prefixed identifier.
    // Or parts of an invocation.
    var isTarget = parent is PrefixedIdentifier && node == parent.prefix;
    var isInvocation = parent is InvocationExpression;
    if (!isTarget && !isInvocation) {
      switch (node.element) {
        case analyzer.LocalVariableElement(name3: _?):
        case analyzer.FormalParameterElement():
          collector.recordVariableLookup(
            node.element,
            node.offset,
            node.length,
          );
      }
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    if (currentExecutionOffset < node.offset ||
        currentExecutionOffset > (node.statements.endToken?.end ?? node.end)) {
      return;
    }

    super.visitSwitchPatternCase(node);
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
