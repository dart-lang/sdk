// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.invocation;

import 'dart:async';

import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for calculating invocation / access suggestions
 * `completion.getSuggestions` request results.
 */
class InvocationComputer extends DartCompletionComputer {

  @override
  bool computeFast(DartCompletionRequest request) {
    // TODO: implement computeFast
    return false;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    return request.node.accept(new _InvocationAstVisitor(request));
  }
}

/**
 * An [AstNode] vistor for determining the appropriate invocation/access
 * suggestions based upon the node in which the completion is requested.
 */
class _InvocationAstVisitor extends GeneralizingAstVisitor<Future<bool>> {
  final DartCompletionRequest request;
  AstNode completionNode;

  _InvocationAstVisitor(this.request);

  @override
  Future<bool> visitNode(AstNode node) {
    return new Future.value(false);
  }

  @override
  Future<bool> visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier == completionNode) {
      return _addSuggestions(node.prefix.bestElement);
    }
    return super.visitPrefixedIdentifier(node);
  }

  @override
  Future<bool> visitSimpleIdentifier(SimpleIdentifier node) {
    completionNode = node;
    return node.parent.accept(this);
  }

  /**
   * Add invocation / access suggestions for the given element.
   */
  Future<bool> _addSuggestions(Element element) {
    if (element != null) {
      return element.accept(new _InvocationElementVisitor(request));
    }
    return new Future.value(false);
  }
}

/**
 * An [Element] visitor for determining the appropriate invocation/access
 * suggestions based upon the element for which the completion is requested.
 */
class _InvocationElementVisitor extends GeneralizingElementVisitor<Future<bool>>
    {
  final DartCompletionRequest request;

  _InvocationElementVisitor(this.request);

  @override
  Future<bool> visitElement(Element element) {
    return new Future.value(false);
  }

  @override
  Future<bool> visitPrefixElement(PrefixElement element) {
    //TODO (danrubel) reimplement to use prefixElement.importedLibraries
    // once that accessor is implemented and available in Dart
    bool modified = false;
    // Find the import directive with the given prefix
    request.unit.directives.forEach((Directive directive) {
      if (directive is ImportDirective) {
        if (directive.prefix != null) {
          if (directive.prefix.name == element.name) {
            // Suggest elements from the imported library
            LibraryElement library = directive.uriElement;
            LibraryElementSuggestionBuilder.suggestionsFor(request, library);
            modified = true;
          }
        }
      }
    });
    return new Future.value(modified);
  }

  @override
  Future<bool> visitVariableElement(VariableElement element) {
    DartType type = element.type;
    if (type != null) {
      ClassElementSuggestionBuilder.suggestionsFor(request, type.element);
    }
    return new Future.value(true);
  }
}
