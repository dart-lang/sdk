// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.common;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../elements/elements.dart';
import '../elements/entities.dart' show AsyncMarker;
import '../enqueue.dart' show DeferredAction;
import '../tree/tree.dart';
import 'registry.dart' show ResolutionRegistry;
import 'scope.dart' show Scope;
import 'type_resolver.dart' show TypeResolver;

class CommonResolverVisitor<R> extends Visitor<R> {
  final Resolution resolution;

  CommonResolverVisitor(this.resolution);

  DiagnosticReporter get reporter => resolution.reporter;

  R visitNode(Node node) {
    return reporter.internalError(
        node, 'internal error: Unhandled node: ${node.getObjectDescription()}');
  }

  R visitEmptyStatement(Node node) => null;

  /** Convenience method for visiting nodes that may be null. */
  R visit(Node node) => (node == null) ? null : node.accept(this);

  void addDeferredAction(Element element, void action()) {
    resolution.enqueuer.addDeferredAction(new DeferredAction(element, action));
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

  MappingVisitor(Resolution resolution, this.registry)
      : typeResolver = new TypeResolver(resolution),
        super(resolution);

  AsyncMarker get currentAsyncMarker => AsyncMarker.SYNC;

  /// Add [element] to the current scope and check for duplicate definitions.
  void addToScope(Element element) {
    if (element is FormalElement && element.isUnnamed) {
      // No duplicate names possible.
      return;
    }
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
        reporter.reportErrorMessage(
            node,
            MessageKind.ASYNC_KEYWORD_AS_IDENTIFIER,
            {'keyword': element.name, 'modifier': currentAsyncMarker});
      }
    }
  }

  /// Register [node] as the definition of [element].
  void defineLocalVariable(Node node, LocalVariableElement element) {
    if (element == null) {
      throw reporter.internalError(node, 'element is null');
    }
    checkLocalDefinitionName(node, element);
    registry.defineElement(node, element);
  }

  void reportDuplicateDefinition(
      String name, Spannable definition, Spannable existing) {
    reporter.reportError(
        reporter.createMessage(
            definition, MessageKind.DUPLICATE_DEFINITION, {'name': name}),
        <DiagnosticMessage>[
          reporter.createMessage(
              existing, MessageKind.EXISTING_DEFINITION, {'name': name}),
        ]);
  }
}
