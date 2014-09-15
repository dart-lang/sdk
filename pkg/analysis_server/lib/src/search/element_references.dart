// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library search.element_references;

import 'dart:async';

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/protocol.dart' show SearchResult;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
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
    var futureGroup = new _ConcatFutureGroup<SearchResult>();
    // find element references
    futureGroup.add(_findElementsReferences(element));
    // add potential references
    if (withPotential && _isMemberElement(element)) {
      String name = element.displayName;
      var matchesFuture = searchEngine.searchMemberReferences(name);
      var resultsFuture = matchesFuture.then((List<SearchMatch> matches) {
        return matches.where((match) => !match.isResolved).map(toResult);
      });
      futureGroup.add(resultsFuture);
    }
    // merge results
    return futureGroup.future;
  }

  /**
   * Returns a [Future] completing with a [List] of references to [element] or
   * to the corresponding hierarchy [Element]s.
   */
  Future<List<SearchResult>> _findElementsReferences(Element element) {
    return _getRefElements(element).then((Iterable<Element> refElements) {
      var futureGroup = new _ConcatFutureGroup<SearchResult>();
      for (Element refElement in refElements) {
        // add declaration
        if (_isDeclarationInteresting(refElement)) {
          SearchResult searchResult = _newDeclarationResult(refElement);
          futureGroup.add(searchResult);
        }
        // do search
        futureGroup.add(_findSingleElementReferences(refElement));
      }
      return futureGroup.future;
    });
  }

  /**
   * Returns a [Future] completing with a [List] of references to [element].
   */
  Future<List<SearchResult>> _findSingleElementReferences(Element element) {
    Future<List<SearchMatch>> matchesFuture =
        searchEngine.searchReferences(element);
    return matchesFuture.then((List<SearchMatch> matches) {
      return matches.map(toResult).toList();
    });
  }

  /**
   * Returns a [Future] completing with [Element]s to search references to.
   *
   * If a [ClassMemberElement] is given, each corresponding [Element] in the
   * hierarchy is returned.
   *
   * Otherwise, only references to [element] should be searched.
   */
  Future<Iterable<Element>> _getRefElements(Element element) {
    if (element is ClassMemberElement) {
      return getHierarchyMembers(searchEngine, element);
    }
    return new Future.value([element]);
  }

  SearchResult _newDeclarationResult(Element refElement) {
    int nameOffset = refElement.nameOffset;
    int nameLength = refElement.name.length;
    SearchMatch searchMatch =
        new SearchMatch(
            MatchKind.DECLARATION,
            refElement,
            new SourceRange(nameOffset, nameLength),
            true,
            false);
    return new SearchResult.fromMatch(searchMatch);
  }

  static SearchResult toResult(SearchMatch match) {
    return new SearchResult.fromMatch(match);
  }

  static bool _isMemberElement(Element element) {
    if (element is ConstructorElement) {
      return false;
    }
    return element.enclosingElement is ClassElement;
  }

  static bool _isDeclarationInteresting(Element element) {
    if (element is LabelElement) {
      return true;
    }
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


/**
 * A collection of [Future]s that concats [List] results of added [Future]s into
 * a single [List].
 */
class _ConcatFutureGroup<E> {
  final List<Future<List<E>>> _futures = <Future<List<E>>>[];

  Future<List<E>> get future {
    return Future.wait(_futures).then(concatToList);
  }

  /**
   * Adds a [Future] or an [E] value to results.
   */
  void add(value) {
    if (value is Future) {
      _futures.add(value);
    } else {
      _futures.add(new Future.value(<E>[value]));
    }
  }
}
