// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js;

import 'package:js_ast/js_ast.dart';
export 'package:js_ast/js_ast.dart';

import '../compiler.dart' show
    Compiler;
import '../diagnostics/spannable.dart' show
    NO_LOCATION_SPANNABLE;
import '../dump_info.dart' show
    DumpInfoTask;
import '../io/code_output.dart' show
    CodeBuffer,
    CodeOutput;
import '../js_emitter/js_emitter.dart' show
    USE_LAZY_EMITTER;

import 'js_source_mapping.dart';

CodeBuffer prettyPrint(Node node,
                       Compiler compiler,
                       {DumpInfoTask monitor,
                        bool allowVariableMinification: true,
                        Renamer renamerForNames:
                            JavaScriptPrintingOptions.identityRenamer}) {
  JavaScriptSourceInformationStrategy sourceInformationFactory =
      compiler.backend.sourceInformationStrategy;
  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions(
      shouldCompressOutput: compiler.enableMinification,
      minifyLocalVariables: allowVariableMinification,
      preferSemicolonToNewlineInMinifiedOutput: USE_LAZY_EMITTER,
      renamerForNames: renamerForNames);
  CodeBuffer outBuffer = new CodeBuffer();
  SourceInformationProcessor sourceInformationProcessor =
      sourceInformationFactory.createProcessor(
          new SourceLocationsMapper(outBuffer));
  Dart2JSJavaScriptPrintingContext context =
      new Dart2JSJavaScriptPrintingContext(
          compiler, monitor, outBuffer, sourceInformationProcessor);
  Printer printer = new Printer(options, context);
  printer.visit(node);
  sourceInformationProcessor.process(node);
  return outBuffer;
}

class Dart2JSJavaScriptPrintingContext implements JavaScriptPrintingContext {
  final Compiler compiler;
  final DumpInfoTask monitor;
  final CodeBuffer outBuffer;
  final CodePositionListener codePositionListener;

  Dart2JSJavaScriptPrintingContext(
      this.compiler,
      this.monitor,
      this.outBuffer,
      this.codePositionListener);

  @override
  void error(String message) {
    compiler.internalError(NO_LOCATION_SPANNABLE, message);
  }

  @override
  void emit(String string) {
    outBuffer.add(string);
  }

  @override
  void enterNode(Node, int startPosition) {}

  @override
  void exitNode(Node node,
                int startPosition,
                int endPosition,
                int closingPosition) {
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

  void countTokens(Node node) => node.accept(this);
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
class UnparsedNode extends DeferredString
                   implements AstContainer {
  @override
  final Node tree;
  final Compiler _compiler;
  final bool _protectForEval;
  LiteralString _cachedLiteral;

  Iterable<Node> get containedNodes => [tree];

  /// A [js.Literal] that represents the string result of unparsing [ast].
  ///
  /// When its string [value] is requested, the node pretty-prints the given
  /// [ast] and, if [protectForEval] is true, wraps the resulting
  /// string in parenthesis. The result is also escaped.
  UnparsedNode(this.tree, this._compiler, this._protectForEval);

  LiteralString get _literal {
    if (_cachedLiteral == null) {
      String text = prettyPrint(tree, _compiler).getText();
      if (_protectForEval) {
        if (tree is Fun) text = '($text)';
        if (tree is LiteralExpression) {
          LiteralExpression literalExpression = tree;
          String template = literalExpression.template;
          if (template.startsWith("function ") ||
          template.startsWith("{")) {
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