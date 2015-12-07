// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.static_member;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/**
 * A contributor for calculating invocation / access suggestions
 * `completion.getSuggestions` request results.
 */
class StaticMemberContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    // Determine if the target looks like a prefixed identifier,
    // a method invocation, or a property access
    SimpleIdentifier targetId = _getTargetId(request.target);
    if (targetId == null) {
      return EMPTY_LIST;
    }

    // Resolve the expression and the containing library
    await request.resolveIdentifier(targetId);
    LibraryElement containingLibrary = await request.libraryElement;
    // Gracefully degrade if the library could not be determined
    // e.g. detached part file or source change
    if (containingLibrary == null) {
      return EMPTY_LIST;
    }

    // Recompute the target since resolution may have changed it
    targetId = _getTargetId(request.target);
    if (targetId == null) {
      return EMPTY_LIST;
    }

    // Build the suggestions
    Element elem = targetId.bestElement;
    if (elem is ClassElement) {
      _SuggestionBuilder builder = new _SuggestionBuilder(containingLibrary);
      elem.accept(builder);
      return builder.suggestions;
    }
    return EMPTY_LIST;
  }

  /**
   * Return the identifier to the left of the 'dot' or `null` if none.
   */
  SimpleIdentifier _getTargetId(CompletionTarget target) {
    AstNode node = target.containingNode;
    if (node is MethodInvocation) {
      if (identical(node.methodName, target.entity)) {
        Expression target = node.realTarget;
        if (target is SimpleIdentifier) {
          return target;
        }
      } else {
        return null;
      }
    }
    if (node is PrefixedIdentifier) {
      if (identical(node.identifier, target.entity)) {
        return node.prefix;
      } else {
        return null;
      }
    }
    return null;
  }
}

/**
 * This class visits elements in a class and provides suggestions based upon
 * the visible static members in that class.
 */
class _SuggestionBuilder extends GeneralizingElementVisitor {
  /**
   * The library containing the unit in which the completion is requested.
   */
  final LibraryElement containingLibrary;

  /**
   * A collection of completion suggestions.
   */
  final List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

  _SuggestionBuilder(this.containingLibrary);

  @override
  visitClassElement(ClassElement element) {
    element.visitChildren(this);
    element.allSupertypes.forEach((InterfaceType type) {
      ClassElement childElem = type.element;
      if (childElem != null) {
        childElem.visitChildren(this);
      }
    });
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  @override
  visitFieldElement(FieldElement element) {
    if (element.isStatic) {
      _addSuggestion(element);
    }
  }

  @override
  visitMethodElement(MethodElement element) {
    if (element.isStatic && !element.isOperator) {
      _addSuggestion(element);
    }
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (element.isStatic) {
      _addSuggestion(element);
    }
  }

  /**
     * Add a suggestion based upon the given element.
     */
  void _addSuggestion(Element element) {
    if (element.isPrivate) {
      if (element.library != containingLibrary) {
        // Do not suggest private members for imported libraries
        return;
      }
    }
    if (element.isSynthetic) {
      if ((element is PropertyAccessorElement) ||
          element is FieldElement && !_isSpecialEnumField(element)) {
        return;
      }
    }
    String completion = element.displayName;
    if (completion == null || completion.length <= 0) {
      return;
    }
    CompletionSuggestion suggestion =
        createSuggestion(element, completion: completion);
    if (suggestion != null) {
      suggestions.add(suggestion);
    }
  }

  /**
     * Determine if the given element is one of the synthetic enum accessors
     * for which we should generate a suggestion.
     */
  bool _isSpecialEnumField(FieldElement element) {
    Element parent = element.enclosingElement;
    if (parent is ClassElement && parent.isEnum) {
      if (element.name == 'values') {
        return true;
      }
    }
    return false;
  }
}
