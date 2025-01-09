// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show SearchResult, newSearchResult_fromMatch;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A computer for `search.findElementReferences` request results.
class ElementReferencesComputer {
  final SearchEngine searchEngine;

  ElementReferencesComputer(this.searchEngine);

  /// Computes [SearchMatch]es for [element] references.
  Future<List<SearchMatch>> compute(
    Element2 element,
    bool withPotential, {
    OperationPerformanceImpl? performance,
  }) async {
    var results = <SearchMatch>[];
    performance ??= OperationPerformanceImpl('<root>');

    // Add element references.
    results.addAll(
      await performance.runAsync(
        '_findElementsReferences',
        (childPerformance) =>
            _findElementsReferences(element, childPerformance),
      ),
    );

    // Add potential references.
    if (withPotential && _isMemberElement(element)) {
      var name = element.displayName;
      var matches = await performance.runAsync(
        'searchEngine.searchMemberReferences',
        (_) => searchEngine.searchMemberReferences(name),
      );
      results.addAll(matches.where((match) => !match.isResolved));
    }

    return results;
  }

  /// Returns a [Future] completing with a [List] of references to [element] or
  /// to the corresponding hierarchy [Element2]s.
  Future<List<SearchMatch>> _findElementsReferences(
    Element2 element,
    OperationPerformanceImpl performance,
  ) async {
    var allResults = <SearchMatch>[];
    var refElements = await performance.runAsync(
      '_getRefElements',
      (childPerformance) => _getRefElements(element, childPerformance),
    );
    for (var refElement in refElements) {
      var elementResults = await performance.runAsync(
        '_findSingleElementReferences',
        (_) => _findSingleElementReferences(refElement),
      );
      allResults.addAll(elementResults);
    }
    return allResults;
  }

  /// Returns a [Future] completing with a [List] of references to [element].
  Future<List<SearchMatch>> _findSingleElementReferences(Element2 element) {
    return searchEngine.searchReferences(element);
  }

  /// Returns a [Future] completing with [Element2]s to search references to.
  ///
  /// If an instance member or a named [FormalParameterElement] is given, each
  /// corresponding [Element2] in the hierarchy is returned.
  ///
  /// Otherwise, only references to [element] should be searched.
  Future<Iterable<Element2>> _getRefElements(
    Element2 element,
    OperationPerformanceImpl performance,
  ) async {
    if (element is FormalParameterElement && element.isNamed) {
      return await performance.runAsync(
        'getHierarchyNamedParameters',
        (_) => getHierarchyNamedParameters(searchEngine, element),
      );
    }
    if (element is MethodElement2 ||
        element is FieldElement2 ||
        element is ConstructorElement2) {
      var (members, parameters) = await performance.runAsync(
        'getHierarchyMembers',
        (performance) => getHierarchyMembersAndParameters(
          searchEngine,
          element,
          performance: performance,
          includeParametersForFields: true,
        ),
      );

      return {...members.map((e) => e), ...parameters.map((e) => e)};
    }
    return [element];
  }

  static SearchResult toResult(SearchMatch match) {
    return newSearchResult_fromMatch(match);
  }

  static bool _isMemberElement(Element2 element) {
    if (element is ConstructorElement2) {
      return false;
    }
    return element.enclosingElement2 is InterfaceElement2;
  }
}
