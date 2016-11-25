// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;

/**
 * A [SearchEngine] implementation.
 */
class SearchEngineImpl2 implements SearchEngine {
  final Iterable<AnalysisDriver> _drivers;

  SearchEngineImpl2(this._drivers);

  @override
  Future<List<SearchMatch>> searchAllSubtypes(ClassElement type) async {
    // TODO(scheglov) implement
    return [];
  }

  @override
  Future<List<SearchMatch>> searchMemberDeclarations(String name) async {
    // TODO(scheglov) implement
    return [];
  }

  @override
  Future<List<SearchMatch>> searchMemberReferences(String name) async {
    // TODO(scheglov) implement
    return [];
  }

  @override
  Future<List<SearchMatch>> searchReferences(Element element) async {
    List<SearchResult> allResults = [];
    for (AnalysisDriver driver in _drivers) {
      List<SearchResult> results = await driver.search.references(element);
      allResults.addAll(results);
    }
    return allResults.map(_SearchMatch.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchSubtypes(ClassElement type) async {
    // TODO(scheglov) implement
    return [];
  }

  @override
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern) async {
    // TODO(scheglov) implement
    return [];
  }
}

class _SearchMatch implements SearchMatch {
  @override
  final String file;

  @override
  final Source librarySource;

  @override
  final Source unitSource;

  @override
  final LibraryElement libraryElement;

  @override
  final Element element;

  @override
  final bool isResolved;

  @override
  final bool isQualified;

  @override
  final MatchKind kind;

  @override
  final SourceRange sourceRange;

  _SearchMatch(
      this.file,
      this.librarySource,
      this.unitSource,
      this.libraryElement,
      this.element,
      this.isResolved,
      this.isQualified,
      this.kind,
      this.sourceRange);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("SearchMatch(kind=");
    buffer.write(kind);
    buffer.write(", libraryUri=");
    buffer.write(librarySource.uri);
    buffer.write(", unitUri=");
    buffer.write(unitSource.uri);
    buffer.write(", range=");
    buffer.write(sourceRange);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(")");
    return buffer.toString();
  }

  static _SearchMatch forSearchResult(SearchResult result) {
    Element enclosingElement = result.enclosingElement;
    return new _SearchMatch(
        enclosingElement.source.fullName,
        enclosingElement.librarySource,
        enclosingElement.source,
        enclosingElement.library,
        enclosingElement,
        result.isResolved,
        result.isQualified,
        toMatchKind(result.kind),
        new SourceRange(result.offset, result.length));
  }

  static MatchKind toMatchKind(SearchResultKind kind) {
    if (kind == SearchResultKind.READ) {
      return MatchKind.READ;
    }
    if (kind == SearchResultKind.READ_WRITE) {
      return MatchKind.READ_WRITE;
    }
    if (kind == SearchResultKind.WRITE) {
      return MatchKind.WRITE;
    }
    if (kind == SearchResultKind.INVOCATION) {
      return MatchKind.INVOCATION;
    }
    return MatchKind.REFERENCE;
  }
}
