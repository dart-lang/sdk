// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/task/api/dart.dart';
import 'package:analyzer/src/task/api/general.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizerResultProviderTest);
    defineReflectiveTests(SummaryDataStoreTest);
  });
}

/// A matcher for ConflictingSummaryException.
const isConflictingSummaryException =
    const TypeMatcher<ConflictingSummaryException>();

UnlinkedPublicNamespace _namespaceWithParts(List<String> parts) {
  _UnlinkedPublicNamespaceMock namespace = new _UnlinkedPublicNamespaceMock();
  namespace.parts = parts;
  return namespace;
}

@reflectiveTest
class ResynthesizerResultProviderTest {
  _SourceFactoryMock sourceFactory = new _SourceFactoryMock();
  _InternalAnalysisContextMock context = new _InternalAnalysisContextMock();
  UniversalCachePartition cachePartition;

  Source source1 = new _SourceMock('package:p1/u1.dart', '/p1/lib/u1.dart');
  Source source2 = new _SourceMock('package:p1/u2.dart', '/p1/lib/u2.dart');
  Source source3 = new _SourceMock('package:p2/u1.dart', '/p2/lib/u1.dart');
  CacheEntry entry1;
  CacheEntry entry2;
  CacheEntry entry3;

  _PackageBundleMock bundle = new _PackageBundleMock();
  _UnlinkedUnitMock unlinkedUnit1 = new _UnlinkedUnitMock();
  _UnlinkedUnitMock unlinkedUnit2 = new _UnlinkedUnitMock();
  _LinkedLibraryMock linkedLibrary = new _LinkedLibraryMock();

  SummaryDataStore dataStore = new SummaryDataStore(<String>[]);
  _TestResynthesizerResultProvider provider;

  void setUp() {
    cachePartition = new UniversalCachePartition(context);
    entry1 = new CacheEntry(source1);
    entry2 = new CacheEntry(source2);
    entry3 = new CacheEntry(source3);
    cachePartition.put(entry1);
    cachePartition.put(entry2);
    cachePartition.put(entry3);

    sourceFactory.resolvedUriMap['package:p1/u1.dart'] = source1;
    sourceFactory.resolvedUriMap['package:p1/u2.dart'] = source2;
    context.sourceFactory = sourceFactory;

    bundle.unlinkedUnitUris = <String>[
      'package:p1/u1.dart',
      'package:p1/u2.dart'
    ];
    bundle.unlinkedUnits = <UnlinkedUnit>[unlinkedUnit1, unlinkedUnit2];
    bundle.linkedLibraryUris = <String>['package:p1/u1.dart'];
    bundle.linkedLibraries = <LinkedLibrary>[linkedLibrary];
    dataStore.addBundle('/p1.ds', bundle);

    unlinkedUnit1.isPartOf = false;
    unlinkedUnit2.isPartOf = true;

    var namespace1 = _namespaceWithParts(['package:p1/u2.dart']);
    var namespace2 = _namespaceWithParts([]);
    unlinkedUnit1.publicNamespace = namespace1;
    unlinkedUnit2.publicNamespace = namespace2;

    provider = new _TestResynthesizerResultProvider(context, dataStore);
    provider.sourcesWithResults.add(source1);
    provider.sourcesWithResults.add(source2);
  }

  test_compute_CONTAINING_LIBRARIES_librarySource() {
    bool success = provider.compute(entry1, CONTAINING_LIBRARIES);
    expect(success, isTrue);
    expect(entry1.getValue(CONTAINING_LIBRARIES), unorderedEquals([source1]));
  }

  test_compute_CONTAINING_LIBRARIES_partSource() {
    bool success = provider.compute(entry2, CONTAINING_LIBRARIES);
    expect(success, isTrue);
    expect(entry2.getValue(CONTAINING_LIBRARIES), unorderedEquals([source1]));
  }

  test_compute_LINE_INFO_emptyLineStarts() {
    unlinkedUnit1.lineStarts = <int>[];
    bool success = provider.compute(entry1, LINE_INFO);
    expect(success, isFalse);
  }

  test_compute_LINE_INFO_hasLineStarts() {
    unlinkedUnit1.lineStarts = <int>[10, 20, 30];
    bool success = provider.compute(entry1, LINE_INFO);
    expect(success, isTrue);
    expect(entry1.getValue(LINE_INFO).lineStarts, <int>[10, 20, 30]);
  }

  test_compute_MODIFICATION_TIME_hasResult() {
    bool success = provider.compute(entry1, MODIFICATION_TIME);
    expect(success, isTrue);
    expect(entry1.getValue(MODIFICATION_TIME), 0);
  }

  test_compute_MODIFICATION_TIME_noResult() {
    bool success = provider.compute(entry3, MODIFICATION_TIME);
    expect(success, isFalse);
    expect(entry3.getState(MODIFICATION_TIME), CacheState.INVALID);
  }

  test_compute_SOURCE_KIND_librarySource() {
    bool success = provider.compute(entry1, SOURCE_KIND);
    expect(success, isTrue);
    expect(entry1.getValue(SOURCE_KIND), SourceKind.LIBRARY);
  }

  test_compute_SOURCE_KIND_librarySource_isPartOf() {
    unlinkedUnit1.isPartOf = true;
    bool success = provider.compute(entry1, SOURCE_KIND);
    expect(success, isTrue);
    expect(entry1.getValue(SOURCE_KIND), SourceKind.PART);
  }

  test_compute_SOURCE_KIND_noResults() {
    bool success = provider.compute(entry3, SOURCE_KIND);
    expect(success, isFalse);
    expect(entry3.getState(SOURCE_KIND), CacheState.INVALID);
  }

  test_compute_SOURCE_KIND_partSource() {
    bool success = provider.compute(entry2, SOURCE_KIND);
    expect(success, isTrue);
    expect(entry2.getValue(SOURCE_KIND), SourceKind.PART);
  }
}

@reflectiveTest
class SummaryDataStoreTest {
  SummaryDataStore dataStore =
      new SummaryDataStore(<String>[], disallowOverlappingSummaries: true);

  _PackageBundleMock bundle1 = new _PackageBundleMock();
  _PackageBundleMock bundle2 = new _PackageBundleMock();
  _UnlinkedUnitMock unlinkedUnit11 = new _UnlinkedUnitMock();
  _UnlinkedUnitMock unlinkedUnit12 = new _UnlinkedUnitMock();
  _UnlinkedUnitMock unlinkedUnit21 = new _UnlinkedUnitMock();
  _LinkedLibraryMock linkedLibrary1 = new _LinkedLibraryMock();
  _LinkedLibraryMock linkedLibrary2 = new _LinkedLibraryMock();

  void setUp() {
    _setupDataStore(dataStore);
  }

  test_addBundle() {
    expect(dataStore.bundles, unorderedEquals([bundle1, bundle2]));
    expect(dataStore.uriToSummaryPath,
        containsPair('package:p1/u1.dart', '/p1.ds'));
    // unlinkedMap
    expect(dataStore.unlinkedMap, hasLength(3));
    expect(dataStore.unlinkedMap,
        containsPair('package:p1/u1.dart', unlinkedUnit11));
    expect(dataStore.unlinkedMap,
        containsPair('package:p1/u2.dart', unlinkedUnit12));
    expect(dataStore.unlinkedMap,
        containsPair('package:p2/u1.dart', unlinkedUnit21));
    // linkedMap
    expect(dataStore.linkedMap, hasLength(2));
    expect(dataStore.linkedMap,
        containsPair('package:p1/u1.dart', linkedLibrary1));
    expect(dataStore.linkedMap,
        containsPair('package:p2/u1.dart', linkedLibrary2));
  }

  test_addBundle_dartUris() {
    _PackageBundleMock bundle = new _PackageBundleMock();
    bundle.unlinkedUnitUris = <String>['dart:core'];
    bundle.unlinkedUnits = <UnlinkedUnit>[unlinkedUnit11];
    bundle.linkedLibraryUris = <String>['dart:core'];
    bundle.linkedLibraries = <LinkedLibrary>[linkedLibrary1];
    bundle.apiSignature = 'signature';
    dataStore.addBundle('/p3.ds', bundle);
  }

  test_addBundle_fileUris() {
    _PackageBundleMock bundle = new _PackageBundleMock();
    bundle.unlinkedUnitUris = <String>['file:/foo.dart'];
    bundle.unlinkedUnits = <UnlinkedUnit>[unlinkedUnit11];
    bundle.linkedLibraryUris = <String>['file:/foo.dart'];
    bundle.linkedLibraries = <LinkedLibrary>[linkedLibrary1];
    bundle.apiSignature = 'signature';
    dataStore.addBundle('/p3.ds', bundle);
  }

  test_addBundle_multiProject() {
    _PackageBundleMock bundle = new _PackageBundleMock();
    bundle.unlinkedUnitUris = <String>[
      'package:p2/u1.dart',
      'package:p1/u1.dart'
    ];
    bundle.unlinkedUnits = <UnlinkedUnit>[unlinkedUnit21, unlinkedUnit11];
    bundle.linkedLibraryUris = <String>[
      'package:p2/u1.dart',
      'package:p1/u1.dart'
    ];
    bundle.linkedLibraries = <LinkedLibrary>[linkedLibrary2, linkedLibrary1];
    bundle.apiSignature = 'signature';
    // p3 conflicts (overlaps) with existing summaries.
    expect(() => dataStore.addBundle('/p3.ds', bundle),
        throwsA(isConflictingSummaryException));
  }

  test_addBundle_multiProjectOverlap() {
    SummaryDataStore dataStore2 =
        new SummaryDataStore(<String>[], disallowOverlappingSummaries: false);
    _setupDataStore(dataStore2);

    _PackageBundleMock bundle = new _PackageBundleMock();
    bundle.unlinkedUnitUris = <String>[
      'package:p2/u1.dart',
      'package:p1/u1.dart'
    ];
    bundle.unlinkedUnits = <UnlinkedUnit>[unlinkedUnit21, unlinkedUnit11];
    bundle.linkedLibraryUris = <String>[
      'package:p2/u1.dart',
      'package:p1/u1.dart'
    ];
    bundle.linkedLibraries = <LinkedLibrary>[linkedLibrary2, linkedLibrary1];
    bundle.apiSignature = 'signature';
    // p3 conflicts (overlaps) with existing summaries, but now allowed.
    dataStore2.addBundle('/p3.ds', bundle);
  }

  test_getContainingLibraryUris_libraryUri() {
    String partUri = 'package:p1/u1.dart';
    List<String> uris = dataStore.getContainingLibraryUris(partUri);
    expect(uris, unorderedEquals([partUri]));
  }

  test_getContainingLibraryUris_partUri() {
    String partUri = 'package:p1/u2.dart';
    List<String> uris = dataStore.getContainingLibraryUris(partUri);
    expect(uris, unorderedEquals(['package:p1/u1.dart']));
  }

  test_getContainingLibraryUris_unknownUri() {
    String partUri = 'package:notInStore/foo.dart';
    List<String> uris = dataStore.getContainingLibraryUris(partUri);
    expect(uris, isNull);
  }

  void _setupDataStore(SummaryDataStore store) {
    var namespace1 = _namespaceWithParts(['package:p1/u2.dart']);
    var namespace2 = _namespaceWithParts([]);
    // bundle1
    unlinkedUnit11.publicNamespace = namespace1;
    unlinkedUnit12.publicNamespace = namespace2;
    bundle1.unlinkedUnitUris = <String>[
      'package:p1/u1.dart',
      'package:p1/u2.dart'
    ];
    bundle1.unlinkedUnits = <UnlinkedUnit>[unlinkedUnit11, unlinkedUnit12];
    bundle1.linkedLibraryUris = <String>['package:p1/u1.dart'];
    bundle1.linkedLibraries = <LinkedLibrary>[linkedLibrary1];
    bundle1.apiSignature = 'signature1';
    store.addBundle('/p1.ds', bundle1);
    // bundle2
    unlinkedUnit21.publicNamespace = namespace2;
    bundle2.unlinkedUnitUris = <String>['package:p2/u1.dart'];
    bundle2.unlinkedUnits = <UnlinkedUnit>[unlinkedUnit21];
    bundle2.linkedLibraryUris = <String>['package:p2/u1.dart'];
    bundle2.linkedLibraries = <LinkedLibrary>[linkedLibrary2];
    bundle2.apiSignature = 'signature2';
    store.addBundle('/p2.ds', bundle2);
  }
}

class _InternalAnalysisContextMock implements InternalAnalysisContext {
  @override
  SourceFactory sourceFactory;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}

class _LinkedLibraryMock implements LinkedLibrary {
  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}

class _PackageBundleMock implements PackageBundle {
  @override
  String apiSignature;

  @override
  List<LinkedLibrary> linkedLibraries;

  @override
  List<String> linkedLibraryUris;

  @override
  List<UnlinkedUnit> unlinkedUnits;

  @override
  List<String> unlinkedUnitUris;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}

class _SourceFactoryMock implements SourceFactory {
  Map<String, Source> resolvedUriMap = <String, Source>{};

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  Source resolveUri(Source containingSource, String containedUri) {
    return resolvedUriMap[containedUri];
  }
}

class _SourceMock implements Source {
  @override
  final Uri uri;

  @override
  final String fullName;

  _SourceMock(String uriStr, this.fullName) : uri = Uri.parse(uriStr);

  @override
  Source get librarySource => null;

  @override
  Source get source => this;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$uri ($fullName)';
}

class _TestResynthesizerResultProvider extends ResynthesizerResultProvider {
  final Set<Source> sourcesWithResults = new Set<Source>();

  _TestResynthesizerResultProvider(
      InternalAnalysisContext context, SummaryDataStore dataStore)
      : super(context, null, dataStore);

  @override
  bool hasResultsForSource(Source source) {
    return sourcesWithResults.contains(source);
  }
}

class _UnlinkedPublicNamespaceMock implements UnlinkedPublicNamespace {
  @override
  List<String> parts;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}

class _UnlinkedUnitMock implements UnlinkedUnit {
  @override
  bool isPartOf;

  @override
  List<int> lineStarts;

  @override
  UnlinkedPublicNamespace publicNamespace;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
