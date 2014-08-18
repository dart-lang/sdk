// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.invocation;

import 'dart:async';

import 'package:analysis_server/src/services/completion/completion_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
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
  Future<bool> visitVariableElement(VariableElement element) {
    return _addSuggestions(element.type);
  }

  Future<bool> _addSuggestions(DartType type) {
    if (type != null && type.element != null) {
      type.element.accept(new _SuggestionBuilderVisitor(request));
      return new Future.value(true);
    }
    return new Future.value(false);
  }
}

/**
 * An [Element] visitor that builds suggestions by recursively visiting
 * elements in a type hierarchy.
 */
class _SuggestionBuilderVisitor extends GeneralizingElementVisitor {
  final DartCompletionRequest request;

  _SuggestionBuilderVisitor(this.request);

  @override
  visitClassElement(ClassElement element) {
    //TODO (danrubel): filter private members if not in the same library
    element.visitChildren(this);
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  @override
  visitFieldElement(FieldElement element) {
    if (!element.isSynthetic) {
      _addSuggestion(element, CompletionSuggestionKind.FIELD);
    }
  }

  @override
  visitMethodElement(MethodElement element) {
    if (!element.isSynthetic) {
      _addSuggestion(element, CompletionSuggestionKind.METHOD);
    }
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!element.isSynthetic) {
      if (element.isGetter) {
        _addSuggestion(element, CompletionSuggestionKind.GETTER);
      } else if (element.isSetter) {
        _addSuggestion(
            element,
            CompletionSuggestionKind.SETTER,
            element.displayName);
      }
    }
  }

  void _addSuggestion(Element element, CompletionSuggestionKind kind,
      [String completion = null]) {
    if (completion == null) {
      completion = element.name;
    }
    if (completion != null && completion.length > 0) {
      request.suggestions.add(
          new CompletionSuggestion(
              kind,
              CompletionRelevance.DEFAULT,
              completion,
              completion.length,
              0,
              element.isDeprecated,
              false));
    }
  }
}
