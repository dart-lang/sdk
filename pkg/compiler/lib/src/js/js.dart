// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js;

import 'package:js_ast/js_ast.dart';

import '../common.dart';
import '../options.dart';
import '../dump_info_javascript_monitor.dart' show DumpInfoJavaScriptMonitor;
import '../io/code_output.dart' show CodeBuffer, CodeOutputListener;
import 'js_source_mapping.dart';

export 'package:js_ast/js_ast.dart';
export 'js_debug.dart';

String prettyPrint(Node node,
    {bool enableMinification = false,
    bool allowVariableMinification = true,
    bool preferSemicolonToNewlineInMinifiedOutput = false}) {
  // TODO(johnniwinther): Do we need all the options here?
  JavaScriptPrintingOptions options = JavaScriptPrintingOptions(
      shouldCompressOutput: enableMinification,
      minifyLocalVariables: allowVariableMinification,
      preferSemicolonToNewlineInMinifiedOutput:
          preferSemicolonToNewlineInMinifiedOutput);
  SimpleJavaScriptPrintingContext context = SimpleJavaScriptPrintingContext();
  Printer printer = Printer(options, context);
  printer.visit(node);
  return context.getText();
}

CodeBuffer createCodeBuffer(Node node, CompilerOptions compilerOptions,
    JavaScriptSourceInformationStrategy sourceInformationStrategy,
    {DumpInfoJavaScriptMonitor? monitor,
    bool allowVariableMinification = true,
    List<CodeOutputListener> listeners = const []}) {
  JavaScriptPrintingOptions options = JavaScriptPrintingOptions(
      utf8: compilerOptions.features.writeUtf8.isEnabled,
      shouldCompressOutput: compilerOptions.enableMinification,
      minifyLocalVariables: allowVariableMinification);
  CodeBuffer outBuffer = CodeBuffer(listeners);
  SourceInformationProcessor sourceInformationProcessor =
      sourceInformationStrategy.createProcessor(
          SourceMapperProviderImpl(outBuffer), const SourceInformationReader());
  Dart2JSJavaScriptPrintingContext context = Dart2JSJavaScriptPrintingContext(
      monitor, outBuffer, sourceInformationProcessor);
  Printer printer = Printer(options, context);
  printer.visit(node);
  sourceInformationProcessor.process(node, outBuffer);
  return outBuffer;
}

class Dart2JSJavaScriptPrintingContext implements JavaScriptPrintingContext {
  final DumpInfoJavaScriptMonitor? monitor;
  final CodeBuffer outBuffer;
  final CodePositionListener codePositionListener;

  Dart2JSJavaScriptPrintingContext(
      this.monitor, this.outBuffer, this.codePositionListener);

  @override
  void error(String message) {
    failedAt(NO_LOCATION_SPANNABLE, message);
  }

  @override
  void emit(String string) {
    monitor?.emit(string);
    outBuffer.add(string);
  }

  @override
  void enterNode(Node node, int startPosition) {
    monitor?.enterNode(node, startPosition);
    codePositionListener.onStartPosition(node, startPosition);
  }

  @override
  void exitNode(
      Node node, int startPosition, int endPosition, int? closingPosition) {
    monitor?.exitNode(node, startPosition, endPosition, closingPosition);
    codePositionListener.onPositions(
        node, startPosition, endPosition, closingPosition);
  }

  @override
  bool get isDebugContext => false;
}

/// Interface for ast nodes that encapsulate an ast that needs to be
/// traversed when counting tokens.
abstract class AstContainer implements Node {
  Iterable<Node> get containedNodes;
}

/// Interface for tasks in the compiler that need to finalize tokens after
/// counting them.
abstract class TokenFinalizer {
  void finalizeTokens();
}

/// Implements reference counting for instances of [ReferenceCountedAstNode]
class TokenCounter extends BaseVisitorVoid {
  @override
  void visitNode(Node node) {
    if (node is AstContainer) {
      for (Node element in node.containedNodes) {
        element.accept(this);
      }
    } else if (node is ReferenceCountedAstNode) {
      node.markSeen(this);
    } else {
      super.visitNode(node);
    }
  }

  void countTokens(Node node) => node.accept(this);
}

abstract class ReferenceCountedAstNode implements Node {
  void markSeen(TokenCounter visitor);
}

/// Represents the LiteralString resulting from unparsing [expression]. The
/// actual unparsing is done on demand when requesting the [value] of this
/// node.
///
/// This is used when generated code needs to be represented as a string,
/// for example by the lazy emitter or when generating code generators.
class UnparsedNode extends DeferredString implements AstContainer {
  final Node tree;
  final bool _enableMinification;
  final bool _protectForEval;
  // TODO(48820): Can be `late final` with initializer.
  LiteralString? _cachedLiteral;

  @override
  Iterable<Node> get containedNodes => [tree];

  /// A [js.Literal] that represents the string result of unparsing [ast].
  ///
  /// When its string [value] is requested, the node pretty-prints the given
  /// [ast] and, if [protectForEval] is true, wraps the resulting string in
  /// parenthesis. The result is also escaped.
  UnparsedNode(this.tree, this._enableMinification, this._protectForEval);

  LiteralString get _literal => _cachedLiteral ??= _create(tree);

  LiteralString _create(Node node) {
    String text = prettyPrint(node, enableMinification: _enableMinification);
    if (_protectForEval) {
      if (node is Fun) text = '($text)';
      if (node is LiteralExpression) {
        String template = node.template;
        if (template.startsWith("function ") || template.startsWith("{")) {
          text = '($text)';
        }
      }
    }
    return js.string(text);
  }

  @override
  String get value => _literal.value;
}

/// True if the given template consists of just a placeholder. Such templates
/// are sometimes used to manually promote the type of an expression.
bool isIdentityTemplate(Template template) {
  return template.ast is InterpolatedExpression;
}

/// Returns `true` if [template] will immediately give a TypeError if the first
/// placeholder is `null` or `undefined`.
bool isNullGuardOnFirstArgument(Template template) {
  // We look for a template of the form
  //
  //     #.something
  //     #.something()
  //
  Node node = template.ast;
  if (node is Call) {
    Call call = node;
    node = call.target;
  }
  if (node is PropertyAccess) {
    final receiver = node.receiver;
    if (receiver is InterpolatedExpression) {
      return receiver.isPositional && receiver.nameOrPosition == 0;
    }
  }
  return false;
}
