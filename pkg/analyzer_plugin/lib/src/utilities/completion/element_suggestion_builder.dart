// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/completion/suggestion_builder.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';

/**
 * Common mixin for sharing behavior.
 */
abstract class ElementSuggestionBuilder {
  // Copied from analysis_server/lib/src/services/completion/dart/suggestion_builder.dart
  /**
   * A collection of completion suggestions.
   */
  final List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

  /**
   * A set of existing completions used to prevent duplicate suggestions.
   */
  final Set<String> _completions = new Set<String>();

  /**
   * A map of element names to suggestions for synthetic getters and setters.
   */
  final Map<String, CompletionSuggestion> _syntheticMap =
      <String, CompletionSuggestion>{};

  /**
   * Return the library in which the completion is requested.
   */
  LibraryElement get containingLibrary;

  /**
   * Return the kind of suggestions that should be built.
   */
  CompletionSuggestionKind get kind;

  /**
   * Return the resource provider used to access the file system.
   */
  ResourceProvider get resourceProvider;

  /**
   * Add a suggestion based upon the given element.
   */
  void addSuggestion(Element element,
      {String prefix, int relevance: DART_RELEVANCE_DEFAULT}) {
    if (element.isPrivate) {
      if (element.library != containingLibrary) {
        return;
      }
    }
    String completion = element.displayName;
    if (prefix != null && prefix.length > 0) {
      if (completion == null || completion.length <= 0) {
        completion = prefix;
      } else {
        completion = '$prefix.$completion';
      }
    }
    if (completion == null || completion.length <= 0) {
      return;
    }
    SuggestionBuilderImpl builder = new SuggestionBuilderImpl(resourceProvider);
    CompletionSuggestion suggestion = builder.forElement(element,
        completion: completion, kind: kind, relevance: relevance);
    if (suggestion != null) {
      if (element.isSynthetic && element is PropertyAccessorElement) {
        String cacheKey;
        if (element.isGetter) {
          cacheKey = element.name;
        }
        if (element.isSetter) {
          cacheKey = element.name;
          cacheKey = cacheKey.substring(0, cacheKey.length - 1);
        }
        if (cacheKey != null) {
          CompletionSuggestion existingSuggestion = _syntheticMap[cacheKey];

          // Pair getter/setter by updating the existing suggestion
          if (existingSuggestion != null) {
            CompletionSuggestion getter =
                element.isGetter ? suggestion : existingSuggestion;
            protocol.ElementKind elemKind =
                element.enclosingElement is ClassElement
                    ? protocol.ElementKind.FIELD
                    : protocol.ElementKind.TOP_LEVEL_VARIABLE;
            existingSuggestion.element = new protocol.Element(
                elemKind,
                existingSuggestion.element.name,
                existingSuggestion.element.flags,
                location: getter.element.location,
                typeParameters: getter.element.typeParameters,
                parameters: null,
                returnType: getter.returnType);
            return;
          }

          // Cache lone getter/setter so that it can be paired
          _syntheticMap[cacheKey] = suggestion;
        }
      }
      if (_completions.add(suggestion.completion)) {
        suggestions.add(suggestion);
      }
    }
  }
}
