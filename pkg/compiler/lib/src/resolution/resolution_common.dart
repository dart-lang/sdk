// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.common;

import '../common/tasks.dart' show
    DeferredAction;
import '../compiler.dart' show
    Compiler;
import '../diagnostics/diagnostic_listener.dart' show
    DiagnosticMessage;
import '../diagnostics/messages.dart' show
    MessageKind;
import '../diagnostics/spannable.dart' show
    Spannable;
import '../elements/elements.dart';
import '../tree/tree.dart';

import 'registry.dart' show
    ResolutionRegistry;
import 'scope.dart' show
    Scope;
import 'type_resolver.dart' show
    TypeResolver;

class CommonResolverVisitor<R> extends Visitor<R> {
  final Compiler compiler;

  CommonResolverVisitor(Compiler this.compiler);

  R visitNode(Node node) {
    return compiler.internalError(node,
        'internal error: Unhandled node: ${node.getObjectDescription()}');
  }

  R visitEmptyStatement(Node node) => null;

  /** Convenience method for visiting nodes that may be null. */
  R visit(Node node) => (node == null) ? null : node.accept(this);

  void addDeferredAction(Element element, DeferredAction action) {
    compiler.enqueuer.resolution.addDeferredAction(element, action);
  }
}

/**
 * Common supertype for resolver visitors that record resolutions in a
 * [ResolutionRegistry].
 */
abstract class MappingVisitor<T> extends CommonResolverVisitor<T> {
  final ResolutionRegistry registry;
  final TypeResolver typeResolver;
  /// The current enclosing element for the visited AST nodes.
  Element get enclosingElement;
  /// The current scope of the visitor.
  Scope get scope;

  MappingVisitor(Compiler compiler, ResolutionRegistry this.registry)
      : typeResolver = new TypeResolver(compiler),
        super(compiler);

  AsyncMarker get currentAsyncMarker => AsyncMarker.SYNC;

  /// Add [element] to the current scope and check for duplicate definitions.
  void addToScope(Element element) {
    Element existing = scope.add(element);
    if (existing != element) {
      reportDuplicateDefinition(element.name, element, existing);
    }
  }

  void checkLocalDefinitionName(Node node, Element element) {
    if (currentAsyncMarker != AsyncMarker.SYNC) {
      if (element.name == 'yield' ||
          element.name == 'async' ||
          element.name == 'await') {
        compiler.reportErrorMessage(
            node, MessageKind.ASYNC_KEYWORD_AS_IDENTIFIER,
            {'keyword': element.name,
             'modifier': currentAsyncMarker});
      }
    }
  }

  /// Register [node] as the definition of [element].
  void defineLocalVariable(Node node, LocalVariableElement element) {
    if (element == null) {
      throw compiler.internalError(node, 'element is null');
    }
    checkLocalDefinitionName(node, element);
    registry.defineElement(node, element);
  }

  void reportDuplicateDefinition(String name,
                                 Spannable definition,
                                 Spannable existing) {
    compiler.reportError(
        compiler.createMessage(
            definition,
            MessageKind.DUPLICATE_DEFINITION,
            {'name': name}),
        <DiagnosticMessage>[
            compiler.createMessage(
                existing,
                MessageKind.EXISTING_DEFINITION,
                {'name': name}),
        ]);
  }
}
