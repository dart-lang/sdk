// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:meta/meta.dart';

/// A contributor that produces suggestions based on the static members of a
/// given class, enum, or extension. More concretely, this class produces
/// suggestions for expressions of the form `C.^`, where `C` is the name of a
/// class, enum, or extension.
class StaticMemberContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var targetId = request.dotTarget;
    if (targetId is Identifier && !request.target.isCascade) {
      var elem = targetId.staticElement;
      if (elem is ClassElement || elem is ExtensionElement) {
        if (request.libraryElement == null) {
          // Gracefully degrade if the library could not be determined, such as
          // a detached part file or source change.
          return const <CompletionSuggestion>[];
        }
        var builder = _SuggestionBuilder(request);
        elem.accept(builder);
        return builder.suggestions;
      }
    }
    return const <CompletionSuggestion>[];
  }
}

/// This class visits elements in a class or extension and provides suggestions
/// based on the visible static members in that class.
class _SuggestionBuilder extends SimpleElementVisitor<void> {
  /// Information about the completion being requested.
  final DartCompletionRequest request;

  /// A collection of completion suggestions.
  final List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

  /// Initialize a newly created suggestion builder.
  _SuggestionBuilder(this.request);

  @override
  void visitClassElement(ClassElement element) {
    element.visitChildren(this);
  }

  @override
  void visitConstructorElement(ConstructorElement element) {
    _addSuggestion(element, element.returnType);
  }

  @override
  void visitExtensionElement(ExtensionElement element) {
    element.visitChildren(this);
  }

  @override
  void visitFieldElement(FieldElement element) {
    if (element.isStatic) {
      _addSuggestion(element, element.type);
    }
  }

  @override
  void visitMethodElement(MethodElement element) {
    if (element.isStatic && !element.isOperator) {
      _addSuggestion(element, element.returnType);
    }
  }

  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (element.isStatic) {
      _addSuggestion(element, element.returnType);
    }
  }

  /// Add a suggestion based on the given [element].
  void _addSuggestion(Element element, DartType elementType) {
    if (element.isPrivate) {
      if (element.library != request.libraryElement) {
        // Don't suggest private members for imported libraries.
        return;
      }
    }
    if (element.isSynthetic) {
      if (element is PropertyAccessorElement ||
          element is FieldElement && !_isSpecialEnumField(element)) {
        return;
      }
    }
    var completion = element.displayName;
    if (completion == null || completion.isEmpty) {
      return;
    }
    var relevance;
    if (request.useNewRelevance) {
      var contextType = request.featureComputer
          .contextTypeFeature(request.contextType, elementType);
      var elementKind = request.featureComputer
          .elementKindFeature(element, request.opType.completionLocation);
      var hasDeprecated = request.featureComputer.hasDeprecatedFeature(element);
      relevance = _computeRelevance(
          contextType: contextType,
          elementKind: elementKind,
          hasDeprecated: hasDeprecated);
    } else {
      relevance =
          element.hasDeprecated ? DART_RELEVANCE_LOW : DART_RELEVANCE_DEFAULT;
    }
    var suggestion = createSuggestion(request, element,
        completion: completion, relevance: relevance);
    if (suggestion != null) {
      suggestions.add(suggestion);
    }
  }

  /// Compute a relevance value from the given feature scores:
  /// - [contextType] is higher if the type of the element matches the context
  ///   type,
  /// - [elementKind] is higher if the kind of element occurs more frequently in
  ///   the given location, and
  /// - [hasDeprecated] is higher if the element is not deprecated.
  int _computeRelevance(
      {@required double contextType,
      @required double elementKind,
      @required double hasDeprecated}) {
    var score = weightedAverage(
        [contextType, elementKind, hasDeprecated], [1.0, 0.75, 0.5]);
    return toRelevance(score, Relevance.member);
  }

  /// Determine whether the [element] is one of the synthetic enum accessors
  /// for which we should generate a suggestion.
  bool _isSpecialEnumField(FieldElement element) {
    var parent = element.enclosingElement;
    if (parent is ClassElement && parent.isEnum) {
      return element.name == 'values';
    }
    return false;
  }
}
