// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library search.element_references;

import 'dart:async';

import 'package:analysis_server/src/search/search_result.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A computer for `search.findElementReferences` request results.
 */
class ElementReferencesComputer {
  final SearchEngine searchEngine;

  ElementReferencesComputer(this.searchEngine);

  /**
   * Computes [SearchResult]s for [element] references.
   */
  Future<List<SearchResult>> compute(Element element, bool withPotential) {
    var futures = <Future<List<SearchResult>>>[];
    // tweak element
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    // prepare Element(s) to find references to
    List<Element> refElements = <Element>[];
    if (element != null) {
      // TODO(scheglov) find all hierarchy members
//      if (element is ClassMemberElement) {
//        refElements = HierarchyUtils.getHierarchyMembers(searchEngine, element);
//      } else {
//        refElements = <Element>[element];
//      }
      refElements = <Element>[element];
    }
    // process each 'refElement'
    for (Element refElement in refElements) {
      // add variable declaration
      if (_isVariableLikeElement(refElement)) {
        int nameOffset = refElement.nameOffset;
        int nameLength = refElement.name.length;
        SearchMatch searchMatch =
            new SearchMatch(
                MatchKind.DECLARATION,
                refElement,
                new SourceRange(nameOffset, nameLength),
                true,
                false);
        SearchResult searchResult = new SearchResult.fromMatch(searchMatch);
        futures.add(new Future.value(<SearchResult>[searchResult]));
      }
      // do search
      Future<List<SearchMatch>> matchesFuture =
          searchEngine.searchReferences(refElement);
      Future<List<SearchResult>> resultsFuture =
          matchesFuture.then((List<SearchMatch> matches) {
        return matches.map(toResult).toList();
      });
      futures.add(resultsFuture);
    }
    // report potential references
    if (withPotential) {
      var matchesFuture = searchEngine.searchMemberReferences(element.name);
      var resultsFuture = matchesFuture.then((List<SearchMatch> matches) {
        return matches.where(
            (match) => !match.isResolved).map(toResult).toList();
      });
      futures.add(resultsFuture);
    }
    // merge results
    var futuresFuture = Future.wait(futures);
    return futuresFuture.then((List<List<SearchResult>> lists) {
      // TODO(scheglov) extract?
      return lists.expand((List<SearchResult> matches) => matches).toList();
    });
  }

  static SearchResult toResult(SearchMatch match) {
    return new SearchResult.fromMatch(match);
  }

  static bool _isVariableLikeElement(Element element) {
    if (element is LocalVariableElement) {
      return true;
    }
    if (element is ParameterElement) {
      return true;
    }
    if (element is PropertyInducingElement) {
      return !element.isSynthetic;
    }
    return false;
  }
}
