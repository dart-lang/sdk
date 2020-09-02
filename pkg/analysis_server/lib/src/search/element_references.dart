// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show SearchResult, newSearchResult_fromMatch;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';

/// A computer for `search.findElementReferences` request results.
class ElementReferencesComputer {
  final SearchEngine searchEngine;

  ElementReferencesComputer(this.searchEngine);

  /// Computes [SearchResult]s for [element] references.
  Future<List<SearchResult>> compute(
      Element element, bool withPotential) async {
    var results = <SearchResult>[];

    // Add element references.
    results.addAll(await _findElementsReferences(element));

    // Add potential references.
    if (withPotential && _isMemberElement(element)) {
      var name = element.displayName;
      var matches = await searchEngine.searchMemberReferences(name);
      matches = SearchMatch.withNotNullElement(matches);
      results.addAll(matches.where((match) => !match.isResolved).map(toResult));
    }

    return results;
  }

  /// Returns a [Future] completing with a [List] of references to [element] or
  /// to the corresponding hierarchy [Element]s.
  Future<List<SearchResult>> _findElementsReferences(Element element) async {
    var allResults = <SearchResult>[];
    var refElements = await _getRefElements(element);
    for (var refElement in refElements) {
      var elementResults = await _findSingleElementReferences(refElement);
      allResults.addAll(elementResults);
    }
    return allResults;
  }

  /// Returns a [Future] completing with a [List] of references to [element].
  Future<List<SearchResult>> _findSingleElementReferences(
      Element element) async {
    var matches = await searchEngine.searchReferences(element);
    matches = SearchMatch.withNotNullElement(matches);
    return matches.map(toResult).toList();
  }

  /// Returns a [Future] completing with [Element]s to search references to.
  ///
  /// If a [ClassMemberElement] or a named [ParameterElement] is given, each
  /// corresponding [Element] in the hierarchy is returned.
  ///
  /// Otherwise, only references to [element] should be searched.
  Future<Iterable<Element>> _getRefElements(Element element) {
    if (element is ParameterElement && element.isNamed) {
      return getHierarchyNamedParameters(searchEngine, element);
    }
    if (element is ClassMemberElement) {
      return getHierarchyMembers(searchEngine, element);
    }
    return Future.value([element]);
  }

  static SearchResult toResult(SearchMatch match) {
    return newSearchResult_fromMatch(match);
  }

  static bool _isMemberElement(Element element) {
    if (element is ConstructorElement) {
      return false;
    }
    return element.enclosingElement is ClassElement;
  }
}
