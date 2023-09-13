// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js;

import 'package:compiler/src/common/codegen.dart';
import 'package:js_ast/js_ast.dart';

import '../common.dart';
import '../js_backend/deferred_holder_expression.dart';
import '../js_backend/string_reference.dart';
import '../js_backend/type_reference.dart';
import '../options.dart';
import '../dump_info.dart' show DumpInfoJsAstRegistry;
import '../io/code_output.dart' show CodeBuffer, CodeOutputListener;
import '../serialization/deferrable.dart';
import '../serialization/serialization.dart';
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
    {DumpInfoJsAstRegistry? monitor,
    JavaScriptAnnotationMonitor annotationMonitor =
        const JavaScriptAnnotationMonitor(),
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
      monitor, outBuffer, sourceInformationProcessor, annotationMonitor);

  /// We defer deserialization of function bodies but maintain maps using
  /// nodes as keys for source map generation. In order to ensure the map's
  /// references are the same between printing and source map generation we
  /// cache the contents of the deferred blocks during these two operations.
  final deferredBlockCollector = _CollectDeferredBlocksAndSetCaches();
  deferredBlockCollector.setCache(node);
  Printer printer = Printer(options, context);
  printer.visit(node);
  sourceInformationProcessor.process(node, outBuffer);
  deferredBlockCollector.clearCache();
  return outBuffer;
}

class _CollectDeferredBlocksAndSetCaches extends BaseVisitorVoid {
  final List<DeferredBlock> _blocks = [];

  _CollectDeferredBlocksAndSetCaches();

  void setCache(Node node) {
    node.accept(this);
  }

  void clearCache() {
    _blocks.forEach((block) => block._clearCache());
    _blocks.clear();
  }

  @override
  void visitBlock(Block node) {
    if (node is DeferredBlock) {
      if (!node._isCached) {
        _blocks.add(node);
        node._setCache();
        super.visitBlock(node);
      }
    } else {
      super.visitBlock(node);
    }
  }
}

class JavaScriptAnnotationMonitor {
  const JavaScriptAnnotationMonitor();

  /// Called for each non-empty list of annotations in the JavaScript tree.
  void onAnnotations(List<Object> annotations) {
    // Should the position of the annotated node be recorded?
  }
}

class Dart2JSJavaScriptPrintingContext implements JavaScriptPrintingContext {
  final DumpInfoJsAstRegistry? monitor;
  final CodeBuffer outBuffer;
  final CodePositionListener codePositionListener;
  final JavaScriptAnnotationMonitor annotationMonitor;

  Dart2JSJavaScriptPrintingContext(this.monitor, this.outBuffer,
      this.codePositionListener, this.annotationMonitor);

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
    final annotations = node.annotations;
    if (annotations.isNotEmpty) {
      annotationMonitor.onAnnotations(annotations);
    }
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
      // The bodies of these are all created without [ReferenceCountedAstNode]
      // so any instances of them can only be injected in via deferred
      // expressions.
      final deferredExpressionData = getNodeDeferredExpressionData(node);
      if (deferredExpressionData != null) {
        deferredExpressionData.modularNames.forEach(visitNode);
        deferredExpressionData.modularExpressions.forEach(visitNode);
        deferredExpressionData.stringReferences.forEach(visitNode);
        deferredExpressionData.typeReferences.forEach(visitNode);
        deferredExpressionData.deferredHolderExpressions.forEach(visitNode);
      } else {
        super.visitNode(node);
      }
    }
  }

  void countTokens(Node node) => node.accept(this);
}

abstract class ReferenceCountedAstNode implements Node {
  void markSeen(TokenCounter visitor);
}

DeferredExpressionData? getNodeDeferredExpressionData(Node node) {
  final annotations = node.annotations;
  if (annotations.isEmpty) return null;
  for (final annotation in annotations) {
    if (annotation is DeferredExpressionData) return annotation;
  }
  return null;
}

/// Contains pointers to deferred expressions within a portion of the AST.
///
/// These objects are attached nodes that have been deserialized but whose
/// bodies are kept in a serialized state. This allows us to skip deserializing
/// the entire function body when we are trying to link these deferred
/// expressions. A [DeferredExpressionData] will be added to
/// [Node.annotations] for these functions. Visitors that just need these
/// deferred expressions should then check the annotations for a [Node] and
/// process them accordingly rather than deserializing all the [Node] children.
class DeferredExpressionData {
  final List<ModularName> modularNames;
  final List<ModularExpression> modularExpressions;
  final List<TypeReference> typeReferences;
  final List<StringReference> stringReferences;
  final List<DeferredHolderExpression> deferredHolderExpressions;

  DeferredExpressionData(this.modularNames, this.modularExpressions)
      : typeReferences = [],
        stringReferences = [],
        deferredHolderExpressions = [];
  DeferredExpressionData._(
      this.modularNames,
      this.modularExpressions,
      this.typeReferences,
      this.stringReferences,
      this.deferredHolderExpressions);

  factory DeferredExpressionData.readFromDataSource(DataSourceReader source) {
    final modularNames =
        source.readListOrNull(() => source.readJsNode() as ModularName) ??
            const [];
    final modularExpressions =
        source.readListOrNull(() => source.readJsNode() as ModularExpression) ??
            const [];
    final typeReferences =
        source.readListOrNull(() => source.readJsNode() as TypeReference) ??
            const [];
    final stringReferences =
        source.readListOrNull(() => source.readJsNode() as StringReference) ??
            const [];
    final deferredHolderExpressions = source.readListOrNull(
            () => source.readJsNode() as DeferredHolderExpression) ??
        const [];
    return DeferredExpressionData._(modularNames, modularExpressions,
        typeReferences, stringReferences, deferredHolderExpressions);
  }

  bool _serializing = false;

  void writeToDataSink(DataSinkWriter sink) {
    // Set [_serializing] so that we don't re-register nodes.
    _serializing = true;
    sink.writeList(modularNames, (ModularName node) => sink.writeJsNode(node));
    sink.writeList(
        modularExpressions, (ModularExpression node) => sink.writeJsNode(node));
    sink.writeList(
        typeReferences, (TypeReference node) => sink.writeJsNode(node));
    sink.writeList(
        stringReferences, (StringReference node) => sink.writeJsNode(node));
    sink.writeList(deferredHolderExpressions,
        (DeferredHolderExpression node) => sink.writeJsNode(node));
    _serializing = false;
  }

  void prepareForSerialization() {
    modularNames.clear();
    modularExpressions.clear();
  }

  void registerModularName(ModularName node) {
    if (_serializing) return;
    modularNames.add(node);
  }

  void registerModularExpression(ModularExpression node) {
    if (_serializing) return;
    modularExpressions.add(node);
  }

  void registerTypeReference(TypeReference node) {
    if (_serializing) return;
    typeReferences.add(node);
  }

  void registerStringReference(StringReference node) {
    if (_serializing) return;
    stringReferences.add(node);
  }

  void registerDeferredHolderExpression(DeferredHolderExpression node) {
    if (_serializing) return;
    deferredHolderExpressions.add(node);
  }
}

/// A code [Block] that has not been fully deserialized but instead holds a
/// [Deferrable] to get the enclosed statements.
///
/// Each time [statements] is invoked, the enclosed [Statement] list will be
/// deserialized so care should be taken to limit this.
class DeferredBlock extends Statement implements Block {
  bool hit = false;
  List<Statement> getLoaded() {
    return _statements.loaded();
  }

  List<Statement>? _cached;

  void _setCache() => _cached = getLoaded();
  void _clearCache() => _cached = null;
  bool get _isCached => _cached != null;

  @override
  List<Statement> get statements => _cached ?? getLoaded();

  final Deferrable<List<Statement>> _statements;

  DeferredBlock(this._statements);

  @override
  T accept<T>(NodeVisitor<T> visitor) {
    return visitor.visitBlock(this);
  }

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    return visitor.visitBlock(this, arg);
  }

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Statement statement in statements) {
      statement.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Statement statement in statements) {
      statement.accept1(visitor, arg);
    }
  }
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
  late final LiteralString _literal = _create(tree);

  @override
  Iterable<Node> get containedNodes => [tree];

  /// A [js.Literal] that represents the string result of unparsing [ast].
  ///
  /// When its string [value] is requested, the node pretty-prints the given
  /// [ast] and, if [protectForEval] is true, wraps the resulting string in
  /// parenthesis. The result is also escaped.
  UnparsedNode(this.tree, this._enableMinification, this._protectForEval);

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
