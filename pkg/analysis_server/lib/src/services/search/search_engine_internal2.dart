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
  Future<Set<ClassElement>> searchAllSubtypes(ClassElement type) async {
    Set<ClassElement> allSubtypes = new Set<ClassElement>();

    Future<Null> addSubtypes(ClassElement type) async {
      List<SearchResult> directResults = await _searchDirectSubtypes(type);
      for (SearchResult directResult in directResults) {
        var directSubtype = directResult.enclosingElement as ClassElement;
        if (allSubtypes.add(directSubtype)) {
          await addSubtypes(directSubtype);
        }
      }
    }

    await addSubtypes(type);
    return allSubtypes;
  }

  @override
  Future<List<SearchMatch>> searchMemberDeclarations(String name) async {
    List<SearchMatch> allDeclarations = [];
    List<AnalysisDriver> drivers = _drivers.toList();
    for (AnalysisDriver driver in drivers) {
      List<Element> elements = await driver.search.classMembers(name);
      allDeclarations.addAll(elements.map(_SearchMatch.forElement));
    }
    return allDeclarations;
  }

  @override
  Future<List<SearchMatch>> searchMemberReferences(String name) async {
    List<SearchResult> allResults = [];
    List<AnalysisDriver> drivers = _drivers.toList();
    for (AnalysisDriver driver in drivers) {
      List<SearchResult> results =
          await driver.search.unresolvedMemberReferences(name);
      allResults.addAll(results);
    }
    return allResults.map(_SearchMatch.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchReferences(Element element) async {
    List<SearchResult> allResults = [];
    List<AnalysisDriver> drivers = _drivers.toList();
    for (AnalysisDriver driver in drivers) {
      List<SearchResult> results = await driver.search.references(element);
      allResults.addAll(results);
    }
    return allResults.map(_SearchMatch.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchSubtypes(ClassElement type) async {
    List<SearchResult> results = await _searchDirectSubtypes(type);
    return results.map(_SearchMatch.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern) async {
    List<SearchMatch> allDeclarations = [];
    RegExp regExp = new RegExp(pattern);
    List<AnalysisDriver> drivers = _drivers.toList();
    for (AnalysisDriver driver in drivers) {
      List<Element> elements = await driver.search.topLevelElements(regExp);
      allDeclarations.addAll(elements.map(_SearchMatch.forElement));
    }
    return allDeclarations;
  }

  Future<List<SearchResult>> _searchDirectSubtypes(ClassElement type) async {
    List<SearchResult> allResults = [];
    List<AnalysisDriver> drivers = _drivers.toList();
    for (AnalysisDriver driver in drivers) {
      List<SearchResult> results = await driver.search.subTypes(type);
      allResults.addAll(results);
    }
    return allResults;
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

  static _SearchMatch forElement(Element element) {
    return new _SearchMatch(
        element.source.fullName,
        element.librarySource,
        element.source,
        element.library,
        element,
        true,
        true,
        MatchKind.DECLARATION,
        new SourceRange(element.nameOffset, element.nameLength));
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
