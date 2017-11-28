// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js;

import 'package:js_ast/js_ast.dart';

import '../common.dart';
import '../options.dart';
import '../dump_info.dart' show DumpInfoTask;
import '../io/code_output.dart' show CodeBuffer;
import 'js_source_mapping.dart';

export 'package:js_ast/js_ast.dart';
export 'js_debug.dart';

String prettyPrint(Node node, CompilerOptions compilerOptions,
    {bool allowVariableMinification: true,
    Renamer renamerForNames: JavaScriptPrintingOptions.identityRenamer}) {
  // TODO(johnniwinther): Do we need all the options here?
  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions(
      shouldCompressOutput: compilerOptions.enableMinification,
      minifyLocalVariables: allowVariableMinification,
      renamerForNames: renamerForNames);
  SimpleJavaScriptPrintingContext context =
      new SimpleJavaScriptPrintingContext();
  Printer printer = new Printer(options, context);
  printer.visit(node);
  return context.getText();
}

CodeBuffer createCodeBuffer(Node node, CompilerOptions compilerOptions,
    JavaScriptSourceInformationStrategy sourceInformationStrategy,
    {DumpInfoTask monitor,
    bool allowVariableMinification: true,
    Renamer renamerForNames: JavaScriptPrintingOptions.identityRenamer}) {
  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions(
      shouldCompressOutput: compilerOptions.enableMinification,
      minifyLocalVariables: allowVariableMinification,
      renamerForNames: renamerForNames);
  CodeBuffer outBuffer = new CodeBuffer();
  SourceInformationProcessor sourceInformationProcessor =
      sourceInformationStrategy.createProcessor(
          new SourceMapperProviderImpl(outBuffer),
          const SourceInformationReader());
  Dart2JSJavaScriptPrintingContext context =
      new Dart2JSJavaScriptPrintingContext(
          monitor, outBuffer, sourceInformationProcessor);
  Printer printer = new Printer(options, context);
  printer.visit(node);
  sourceInformationProcessor.process(node, outBuffer);
  return outBuffer;
}

class Dart2JSJavaScriptPrintingContext implements JavaScriptPrintingContext {
  final DumpInfoTask monitor;
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
    outBuffer.add(string);
  }

  @override
  void enterNode(Node node, int startPosition) {
    codePositionListener.onStartPosition(node, startPosition);
  }

  @override
  void exitNode(
      Node node, int startPosition, int endPosition, int closingPosition) {
    if (monitor != null) {
      monitor.recordAstSize(node, endPosition - startPosition);
    }
    codePositionListener.onPositions(
        node, startPosition, endPosition, closingPosition);
  }
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
class TokenCounter extends BaseVisitor {
  @override
  visitNode(Node node) {
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

  // TODO(28763): Remove `<dynamic>` when issue 28763 is fixed.
  void countTokens(Node node) => node.accept<dynamic>(this);
}

abstract class ReferenceCountedAstNode implements Node {
  markSeen(TokenCounter visitor);
}

/// Represents the LiteralString resulting from unparsing [expression]. The
/// actual unparsing is done on demand when requesting the [value] of this
/// node.
///
/// This is used when generated code needs to be represented as a string,
/// for example by the lazy emitter or when generating code generators.
class UnparsedNode extends DeferredString implements AstContainer {
  final Node tree;
  final CompilerOptions _compilerOptions;
  final bool _protectForEval;
  LiteralString _cachedLiteral;

  Iterable<Node> get containedNodes => [tree];

  /// A [js.Literal] that represents the string result of unparsing [ast].
  ///
  /// When its string [value] is requested, the node pretty-prints the given
  /// [ast] and, if [protectForEval] is true, wraps the resulting string in
  /// parenthesis. The result is also escaped.
  UnparsedNode(this.tree, this._compilerOptions, this._protectForEval);

  LiteralString get _literal {
    if (_cachedLiteral == null) {
      String text = prettyPrint(tree, _compilerOptions);
      if (_protectForEval) {
        if (tree is Fun) text = '($text)';
        if (tree is LiteralExpression) {
          LiteralExpression literalExpression = tree;
          String template = literalExpression.template;
          if (template.startsWith("function ") || template.startsWith("{")) {
            text = '($text)';
          }
        }
      }
      _cachedLiteral = js.escapedString(text);
    }
    return _cachedLiteral;
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
    PropertyAccess access = node;
    if (access.receiver is InterpolatedExpression) {
      InterpolatedExpression hole = access.receiver;
      return hole.isPositional && hole.nameOrPosition == 0;
    }
  }
  return false;
}
