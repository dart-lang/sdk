// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show SearchResult, newSearchResult_fromMatch;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A computer for `search.findElementReferences` request results.
class ElementReferencesComputer {
  final SearchEngine searchEngine;

  ElementReferencesComputer(this.searchEngine);

  /// Computes [SearchMatch]es for [element] references.
  Future<List<SearchMatch>> compute(Element element, bool withPotential,
      {OperationPerformanceImpl? performance}) async {
    var results = <SearchMatch>[];
    performance ??= OperationPerformanceImpl('<root>');

    // Add element references.
    results.addAll(await performance.runAsync(
        '_findElementsReferences',
        (childPerformance) =>
            _findElementsReferences(element, childPerformance)));

    // Add potential references.
    if (withPotential && _isMemberElement(element)) {
      var name = element.displayName;
      var matches = await performance.runAsync(
          'searchEngine.searchMemberReferences',
          (_) => searchEngine.searchMemberReferences(name));
      results.addAll(matches.where((match) => !match.isResolved));
    }

    return results;
  }

  /// Returns a [Future] completing with a [List] of references to [element] or
  /// to the corresponding hierarchy [Element]s.
  Future<List<SearchMatch>> _findElementsReferences(
      Element element, OperationPerformanceImpl performance) async {
    var allResults = <SearchMatch>[];
    var refElements = await performance.runAsync('_getRefElements',
        (childPerformance) => _getRefElements(element, childPerformance));
    for (var refElement in refElements) {
      var elementResults = await performance.runAsync(
          '_findSingleElementReferences',
          (_) => _findSingleElementReferences(refElement));
      allResults.addAll(elementResults);
    }
    return allResults;
  }

  /// Returns a [Future] completing with a [List] of references to [element].
  Future<List<SearchMatch>> _findSingleElementReferences(
      Element element) async {
    return searchEngine.searchReferences(element);
  }

  /// Returns a [Future] completing with [Element]s to search references to.
  ///
  /// If a [ClassMemberElement] or a named [ParameterElement] is given, each
  /// corresponding [Element] in the hierarchy is returned.
  ///
  /// Otherwise, only references to [element] should be searched.
  Future<Iterable<Element>> _getRefElements(
      Element element, OperationPerformanceImpl performance) {
    if (element is ParameterElement && element.isNamed) {
      return performance.runAsync('getHierarchyNamedParameters',
          (_) => getHierarchyNamedParameters(searchEngine, element));
    }
    if (element is ClassMemberElement) {
      return performance.runAsync(
          'getHierarchyMembers',
          (performance) => getHierarchyMembers(searchEngine, element,
              performance: performance));
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
    return element.enclosingElement is InterfaceElement;
  }
}
