// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

import '../../../protocol_server.dart' show CompletionSuggestion;

/**
 * A contributor for calculating static member invocation / access suggestions
 * `completion.getSuggestions` request results.
 */
class StaticMemberContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    Expression targetId = request.dotTarget;
    if (targetId is Identifier && !request.target.isCascade) {
      Element elem = targetId.bestElement;
      if (elem is ClassElement) {
        LibraryElement containingLibrary = request.libraryElement;
        // Gracefully degrade if the library could not be determined
        // e.g. detached part file or source change
        if (containingLibrary == null) {
          return EMPTY_LIST;
        }

        _SuggestionBuilder builder =
            new _SuggestionBuilder(containingLibrary, request.ideOptions);
        elem.accept(builder);
        return builder.suggestions;
      }
    }
    return EMPTY_LIST;
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

  /**
   * Ide options.
   */
  final IdeOptions options;

  _SuggestionBuilder(this.containingLibrary, this.options);

  @override
  visitClassElement(ClassElement element) {
    element.visitChildren(this);
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
        createSuggestion(element, options, completion: completion);
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
