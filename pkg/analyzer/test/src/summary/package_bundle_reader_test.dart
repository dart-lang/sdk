// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizerResultProviderTest);
    defineReflectiveTests(SummaryDataStoreTest);
  });
}

UnlinkedPublicNamespace _namespaceWithParts(List<String> parts) {
  UnlinkedPublicNamespace namespace = new _UnlinkedPublicNamespaceMock();
  when(namespace.parts).thenReturn(parts);
  return namespace;
}

@reflectiveTest
class ResynthesizerResultProviderTest {
  SourceFactory sourceFactory = new _SourceFactoryMock();
  InternalAnalysisContext context = new _InternalAnalysisContextMock();
  UniversalCachePartition cachePartition;

  Source source1 = new _SourceMock('package:p1/u1.dart', '/p1/lib/u1.dart');
  Source source2 = new _SourceMock('package:p1/u2.dart', '/p1/lib/u2.dart');
  Source source3 = new _SourceMock('package:p2/u1.dart', '/p2/lib/u1.dart');
  CacheEntry entry1;
  CacheEntry entry2;
  CacheEntry entry3;

  PackageBundle bundle = new _PackageBundleMock();
  UnlinkedUnit unlinkedUnit1 = new _UnlinkedUnitMock();
  UnlinkedUnit unlinkedUnit2 = new _UnlinkedUnitMock();
  LinkedLibrary linkedLibrary = new _LinkedLibraryMock();

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

    when(sourceFactory.resolveUri(anyObject, 'package:p1/u1.dart'))
        .thenReturn(source1);
    when(sourceFactory.resolveUri(anyObject, 'package:p1/u2.dart'))
        .thenReturn(source2);
    when(context.sourceFactory).thenReturn(sourceFactory);

    when(bundle.unlinkedUnitUris)
        .thenReturn(<String>['package:p1/u1.dart', 'package:p1/u2.dart']);
    when(bundle.unlinkedUnits)
        .thenReturn(<UnlinkedUnit>[unlinkedUnit1, unlinkedUnit2]);
    when(bundle.linkedLibraryUris).thenReturn(<String>['package:p1/u1.dart']);
    when(bundle.linkedLibraries).thenReturn(<LinkedLibrary>[linkedLibrary]);
    dataStore.addBundle('/p1.ds', bundle);

    when(unlinkedUnit1.isPartOf).thenReturn(false);
    when(unlinkedUnit2.isPartOf).thenReturn(true);

    when(unlinkedUnit1.publicNamespace)
        .thenReturn(_namespaceWithParts(['package:p1/u2.dart']));
    when(unlinkedUnit2.publicNamespace).thenReturn(_namespaceWithParts([]));

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
    when(unlinkedUnit1.lineStarts).thenReturn(<int>[]);
    bool success = provider.compute(entry1, LINE_INFO);
    expect(success, isFalse);
  }

  test_compute_LINE_INFO_hasLineStarts() {
    when(unlinkedUnit1.lineStarts).thenReturn(<int>[10, 20, 30]);
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
    when(unlinkedUnit1.isPartOf).thenReturn(true);
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
      new SummaryDataStore(<String>[], recordDependencyInfo: true);

  PackageBundle bundle1 = new _PackageBundleMock();
  PackageBundle bundle2 = new _PackageBundleMock();
  UnlinkedUnit unlinkedUnit11 = new _UnlinkedUnitMock();
  UnlinkedUnit unlinkedUnit12 = new _UnlinkedUnitMock();
  UnlinkedUnit unlinkedUnit21 = new _UnlinkedUnitMock();
  LinkedLibrary linkedLibrary1 = new _LinkedLibraryMock();
  LinkedLibrary linkedLibrary2 = new _LinkedLibraryMock();

  void setUp() {
    // bundle1
    when(unlinkedUnit11.publicNamespace)
        .thenReturn(_namespaceWithParts(['package:p1/u2.dart']));
    when(unlinkedUnit12.publicNamespace).thenReturn(_namespaceWithParts([]));
    when(bundle1.unlinkedUnitUris)
        .thenReturn(<String>['package:p1/u1.dart', 'package:p1/u2.dart']);
    when(bundle1.unlinkedUnits)
        .thenReturn(<UnlinkedUnit>[unlinkedUnit11, unlinkedUnit12]);
    when(bundle1.linkedLibraryUris).thenReturn(<String>['package:p1/u1.dart']);
    when(bundle1.linkedLibraries).thenReturn(<LinkedLibrary>[linkedLibrary1]);
    when(bundle1.apiSignature).thenReturn('signature1');
    dataStore.addBundle('/p1.ds', bundle1);
    // bundle2
    when(unlinkedUnit21.publicNamespace).thenReturn(_namespaceWithParts([]));
    when(bundle2.unlinkedUnitUris).thenReturn(<String>['package:p2/u1.dart']);
    when(bundle2.unlinkedUnits).thenReturn(<UnlinkedUnit>[unlinkedUnit21]);
    when(bundle2.linkedLibraryUris).thenReturn(<String>['package:p2/u1.dart']);
    when(bundle2.linkedLibraries).thenReturn(<LinkedLibrary>[linkedLibrary2]);
    when(bundle2.apiSignature).thenReturn('signature2');
    dataStore.addBundle('/p2.ds', bundle2);
  }

  test_addBundle() {
    expect(dataStore.bundles, unorderedEquals([bundle1, bundle2]));
    expect(dataStore.dependencies[0].summaryPath, '/p1.ds');
    expect(dataStore.dependencies[0].apiSignature, 'signature1');
    expect(dataStore.dependencies[0].includedPackageNames, ['p1']);
    expect(dataStore.dependencies[0].includesFileUris, false);
    expect(dataStore.dependencies[0].includesDartUris, false);
    expect(dataStore.dependencies[1].summaryPath, '/p2.ds');
    expect(dataStore.dependencies[1].apiSignature, 'signature2');
    expect(dataStore.dependencies[1].includedPackageNames, ['p2']);
    expect(dataStore.dependencies[1].includesFileUris, false);
    expect(dataStore.dependencies[1].includesDartUris, false);
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
    PackageBundle bundle = new _PackageBundleMock();
    when(bundle.unlinkedUnitUris).thenReturn(<String>['dart:core']);
    when(bundle.unlinkedUnits).thenReturn(<UnlinkedUnit>[unlinkedUnit11]);
    when(bundle.linkedLibraryUris).thenReturn(<String>['dart:core']);
    when(bundle.linkedLibraries).thenReturn(<LinkedLibrary>[linkedLibrary1]);
    when(bundle.apiSignature).thenReturn('signature');
    dataStore.addBundle('/p3.ds', bundle);
    expect(dataStore.dependencies.last.includedPackageNames, []);
    expect(dataStore.dependencies.last.includesFileUris, false);
    expect(dataStore.dependencies.last.includesDartUris, true);
  }

  test_addBundle_fileUris() {
    PackageBundle bundle = new _PackageBundleMock();
    when(bundle.unlinkedUnitUris).thenReturn(<String>['file:/foo.dart']);
    when(bundle.unlinkedUnits).thenReturn(<UnlinkedUnit>[unlinkedUnit11]);
    when(bundle.linkedLibraryUris).thenReturn(<String>['file:/foo.dart']);
    when(bundle.linkedLibraries).thenReturn(<LinkedLibrary>[linkedLibrary1]);
    when(bundle.apiSignature).thenReturn('signature');
    dataStore.addBundle('/p3.ds', bundle);
    expect(dataStore.dependencies.last.includedPackageNames, []);
    expect(dataStore.dependencies.last.includesFileUris, true);
    expect(dataStore.dependencies.last.includesDartUris, false);
  }

  test_addBundle_multiProject() {
    PackageBundle bundle = new _PackageBundleMock();
    when(bundle.unlinkedUnitUris)
        .thenReturn(<String>['package:p2/u1.dart', 'package:p1/u1.dart']);
    when(bundle.unlinkedUnits)
        .thenReturn(<UnlinkedUnit>[unlinkedUnit21, unlinkedUnit11]);
    when(bundle.linkedLibraryUris)
        .thenReturn(<String>['package:p2/u1.dart', 'package:p1/u1.dart']);
    when(bundle.linkedLibraries)
        .thenReturn(<LinkedLibrary>[linkedLibrary2, linkedLibrary1]);
    when(bundle.apiSignature).thenReturn('signature');
    dataStore.addBundle('/p3.ds', bundle);
    expect(dataStore.dependencies.last.includedPackageNames, ['p1', 'p2']);
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
}

class _InternalAnalysisContextMock extends TypedMock
    implements InternalAnalysisContext {}

class _LinkedLibraryMock extends TypedMock implements LinkedLibrary {}

class _PackageBundleMock extends TypedMock implements PackageBundle {}

class _SourceFactoryMock extends TypedMock implements SourceFactory {}

class _SourceMock implements Source {
  final Uri uri;
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
      : super(context, dataStore);

  @override
  bool hasResultsForSource(Source source) {
    return sourcesWithResults.contains(source);
  }
}

class _UnlinkedPublicNamespaceMock extends TypedMock
    implements UnlinkedPublicNamespace {}

class _UnlinkedUnitMock extends TypedMock implements UnlinkedUnit {}
