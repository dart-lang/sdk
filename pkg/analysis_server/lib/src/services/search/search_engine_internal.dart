// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A [SearchEngine] implementation.
class SearchEngineImpl implements SearchEngine {
  final Iterable<AnalysisDriver> _drivers;

  new(this._drivers);

  @override
  Future<void> appendAllSubtypes(
    InterfaceElement type,
    Set<InterfaceElement> allSubtypes,
    OperationPerformanceImpl performance,
  ) async {
    Future<void> addSubtypes(InterfaceElement type) async {
      var directResults = await performance.runAsync(
        '_searchDirectSubtypes',
        (performance) => _searchDirectSubtypes(type, performance),
      );
      for (var directResult in directResults) {
        var directSubtype =
            directResult.enclosingFragment.element as InterfaceElement;
        if (allSubtypes.add(directSubtype)) {
          await addSubtypes(directSubtype);
        }
      }
    }

    await addSubtypes(type);
  }

  @override
  Future<Set<String>?> membersOfSubtypes(InterfaceElement type) async {
    var drivers = _drivers.toList();
    _discoverAvailableFiles(drivers);

    var libraryFile = type.library.firstFragment.source.mustBeFile;

    var hasSubtypes = false;
    var visitedIds = <String>{};
    var members = <String>{};

    Future<void> addMembers(
      InterfaceElement? type,
      SubtypeResult? subtype,
    ) async {
      if (subtype != null && !visitedIds.add(subtype.id)) {
        return;
      }
      for (var driver in drivers) {
        var subtypes = await driver.search.subtypes(
          type: type,
          subtype: subtype,
        );
        for (var subtype in subtypes) {
          hasSubtypes = true;
          members.addAll(
            subtype.library.resource == libraryFile
                ? subtype.members
                : subtype.members.where((name) => !name.startsWith('_')),
          );
          await addMembers(null, subtype);
        }
      }
    }

    await addMembers(type, null);

    if (!hasSubtypes) {
      return null;
    }
    return members;
  }

  @override
  Future<List<LibraryFragmentSearchMatch>> searchLibraryFragmentReferences(
    LibraryFragment fragment,
  ) async {
    var allResults = <LibraryFragmentSearchMatch>[];
    var drivers = _drivers.toList();
    _discoverAvailableFiles(drivers);
    for (var driver in drivers) {
      var results = await driver.search.referencesLibraryFragment(fragment);
      allResults.addAll(results);
    }
    return allResults;
  }

  @override
  Future<List<LibraryFragmentSearchMatch>> searchLibraryImportReferences(
    LibraryImport import,
  ) async {
    var allResults = <LibraryFragmentSearchMatch>[];
    var drivers = _drivers.toList();
    _discoverAvailableFiles(drivers);
    for (var driver in drivers) {
      var results = await driver.search.referencesLibraryImport(import);
      allResults.addAll(results);
    }
    return allResults;
  }

  @override
  Future<List<SearchMatch>> searchMemberDeclarations(String name) async {
    var allDeclarations = <SearchMatch>[];
    var drivers = _drivers.toList();
    _discoverAvailableFiles(drivers);
    for (var driver in drivers) {
      var elements = await driver.search.classMembers(name);
      allDeclarations.addAll(elements.map(SearchMatchImpl.forElement));
    }
    return allDeclarations;
  }

  @override
  Future<List<SearchMatch>> searchMemberReferences(String name) async {
    var allResults = <SearchResult>[];
    var drivers = _drivers.toList();
    _discoverAvailableFiles(drivers);
    for (var driver in drivers) {
      var results = await driver.search.unresolvedMemberReferences(name);
      allResults.addAll(results);
    }
    return allResults.map(SearchMatchImpl.forSearchResult).toList();
  }

  @override
  Future<Set<String>> searchPrefixesUsedInLibrary(
    covariant LibraryElementImpl library,
    Element element,
  ) async {
    var driver =
        (library.session.analysisContext as DriverBasedAnalysisContext).driver;
    return await driver.search.prefixesUsedInLibrary(library, element);
  }

  @override
  Future<List<SearchMatch>> searchReferences(Element element) async {
    var allResults = <SearchResult>[];
    var drivers = _drivers.toList();
    _discoverAvailableFiles(drivers);
    for (var driver in drivers) {
      var results = await driver.search.references(element);
      allResults.addAll(results);
    }
    return allResults.map(SearchMatchImpl.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchSubtypes(
    InterfaceElement type, {
    OperationPerformanceImpl? performance,
  }) async {
    performance ??= OperationPerformanceImpl('<root>');
    var results = await _searchDirectSubtypes(type, performance);
    return results.map(SearchMatchImpl.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern) async {
    var allMatches = <SearchMatch>[];
    var regExp = RegExp(pattern);
    var drivers = _drivers.toList();
    _discoverAvailableFiles(drivers);
    for (var driver in drivers) {
      var elements = await driver.search.topLevelElements(regExp);
      allMatches.addAll(elements.map(SearchMatchImpl.forElement));
    }
    return allMatches;
  }

  void _discoverAvailableFiles(List<AnalysisDriver> drivers) {
    for (var driver in drivers) {
      driver.discoverAvailableFiles();
    }
  }

  Future<List<SearchResult>> _searchDirectSubtypes(
    InterfaceElement type,
    OperationPerformanceImpl performance,
  ) async {
    var allResults = <SearchResult>[];

    var drivers = _drivers.toList();
    _discoverAvailableFiles(drivers);
    for (var driver in drivers) {
      var results = await performance.runAsync(
        'subTypes',
        (_) => driver.search.subTypes(type),
      );
      allResults.addAll(results);
    }
    return allResults;
  }
}

class SearchMatchImpl implements SearchMatch {
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

  new(
    this.file,
    this.librarySource,
    this.unitSource,
    this.libraryElement,
    this.element,
    this.isResolved,
    this.isQualified,
    this.kind,
    this.sourceRange,
  );

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write('SearchMatch(kind=');
    buffer.write(kind);
    buffer.write(', libraryUri=');
    buffer.write(librarySource.uri);
    buffer.write(', unitUri=');
    buffer.write(unitSource.uri);
    buffer.write(', range=');
    buffer.write(sourceRange);
    buffer.write(', isResolved=');
    buffer.write(isResolved);
    buffer.write(', isQualified=');
    buffer.write(isQualified);
    buffer.write(')');
    return buffer.toString();
  }

  static SearchMatchImpl forElement(Element element) {
    // Although we use the element for the result, we use nonSynthetic for
    // everything related to the location.
    var nonSynthetic = element.nonSynthetic;
    var firstFragment = nonSynthetic.firstFragment;
    var libraryFragment = firstFragment.libraryFragment!;
    return SearchMatchImpl(
      libraryFragment.source.fullName,
      libraryFragment.element.firstFragment.source,
      libraryFragment.source,
      libraryFragment.element,
      element,
      true,
      true,
      MatchKind.DECLARATION,
      SourceRange(firstFragment.nameOffset!, firstFragment.name!.length),
    );
  }

  static SearchMatchImpl forSearchResult(SearchResult result) {
    var firstFragment = result.enclosingFragment;
    var libraryFragment = firstFragment.libraryFragment!;
    return SearchMatchImpl(
      libraryFragment.source.fullName,
      libraryFragment.element.firstFragment.source,
      libraryFragment.source,
      libraryFragment.element,
      result.enclosingFragment.element,
      result.isResolved,
      result.isQualified,
      toMatchKind(result.kind),
      SourceRange(result.offset, result.length),
    );
  }

  static MatchKind toMatchKind(SearchResultKind kind) {
    return switch (kind) {
      SearchResultKind.READ => MatchKind.READ,
      SearchResultKind.READ_WRITE => MatchKind.READ_WRITE,
      SearchResultKind.WRITE => MatchKind.WRITE,
      SearchResultKind.INVOCATION => MatchKind.INVOCATION,
      SearchResultKind.DOT_SHORTHANDS_CONSTRUCTOR_TEAR_OFF =>
        MatchKind.DOT_SHORTHANDS_CONSTRUCTOR_TEAR_OFF,
      SearchResultKind.DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION =>
        MatchKind.DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION,
      SearchResultKind.REFERENCE_BY_NAMED_ARGUMENT =>
        MatchKind.REFERENCE_BY_NAMED_ARGUMENT,
      SearchResultKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS =>
        MatchKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS,
      SearchResultKind.REFERENCE_BY_CONSTRUCTOR_TEAR_OFF =>
        MatchKind.REFERENCE_BY_CONSTRUCTOR_TEAR_OFF,
      SearchResultKind.REFERENCE_IN_EXTENDS_CLAUSE =>
        MatchKind.REFERENCE_IN_EXTENDS_CLAUSE,
      SearchResultKind.REFERENCE_IN_IMPLEMENTS_CLAUSE =>
        MatchKind.REFERENCE_IN_IMPLEMENTS_CLAUSE,
      SearchResultKind.REFERENCE_IN_ON_CLAUSE =>
        MatchKind.REFERENCE_IN_ON_CLAUSE,
      SearchResultKind.REFERENCE_IN_WITH_CLAUSE =>
        MatchKind.REFERENCE_IN_WITH_CLAUSE,
      SearchResultKind.REFERENCE_IN_PATTERN_FIELD =>
        MatchKind.REFERENCE_IN_PATTERN_FIELD,
      _ => MatchKind.REFERENCE,
    };
  }
}

extension _SourceExtension on Source {
  /// Returns the [File] for this source.
  ///
  /// This assumes that the source is a [FileSource], which is safe because
  /// index and search are only supported in DAS, where all sources are file
  /// based.
  File get mustBeFile {
    return (this as FileSource).file;
  }
}
