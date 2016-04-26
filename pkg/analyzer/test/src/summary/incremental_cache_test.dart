// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/incremental_cache.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../abstract_single_unit.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(IncrementalCacheTest);
}

/**
 * TODO(scheglov) write more tests for invalidation.
 */
@reflectiveTest
class IncrementalCacheTest extends AbstractSingleUnitTest {
  _TestCacheStorage storage = new _TestCacheStorage();
  IncrementalCache cache;

  Source putLibrary(String path, String code) {
    Source source = addSource(path, code);
    LibraryElement libraryElement = context.computeLibraryElement(source);
    cache.putLibrary(libraryElement);
    return source;
  }

  void putTestLibrary(String code) {
    resolveTestUnit(code);
    cache.putLibrary(testLibraryElement);
  }

  @override
  void setUp() {
    super.setUp();
    cache = new IncrementalCache(storage, context, <int>[]);
  }

  void test_getLibraryClosureBundles_emptyCache() {
    resolveTestUnit('main() {}');
    // the cache is empty, no bundles
    List<LibraryBundleWithId> bundles =
        cache.getLibraryClosureBundles(testSource);
    expect(bundles, isNull);
  }

  void test_getLibraryClosureBundles_exportLib() {
    Source aSource = putLibrary('/a.dart', '');
    putTestLibrary(r'''
import 'a.dart';
main() {}
''');
    List<LibraryBundleWithId> bundles =
        cache.getLibraryClosureBundles(testSource);
    expect(bundles, isNotNull);
    expect(_getBundleSources(bundles), [testSource, aSource].toSet());
    // remove the 'a.dart' bundle, 'test.dart' loading fails
    cache.clearInternalCaches();
    storage.map.remove(_findBundleForSource(bundles, aSource).id);
    expect(cache.getLibraryClosureBundles(testSource), isNull);
  }

  void test_getLibraryClosureBundles_importLib() {
    Source aSource = putLibrary('/a.dart', '');
    putTestLibrary(r'''
import 'a.dart';
main() {}
''');
    List<LibraryBundleWithId> bundles =
        cache.getLibraryClosureBundles(testSource);
    expect(bundles, isNotNull);
    expect(_getBundleSources(bundles), [testSource, aSource].toSet());
    // remove the 'a.dart' bundle, 'test.dart' loading fails
    cache.clearInternalCaches();
    storage.map.remove(_findBundleForSource(bundles, aSource).id);
    expect(cache.getLibraryClosureBundles(testSource), isNull);
  }

  void test_getLibraryClosureBundles_importLib2() {
    Source aSource = putLibrary('/a.dart', '');
    Source bSource = putLibrary('/b.dart', "import 'a.dart';");
    putTestLibrary(r'''
import 'b.dart';
main() {}
''');
    List<LibraryBundleWithId> bundles =
        cache.getLibraryClosureBundles(testSource);
    expect(bundles, isNotNull);
    expect(_getBundleSources(bundles), [testSource, aSource, bSource].toSet());
    // remove the 'a.dart' bundle, 'test.dart' loading fails
    cache.clearInternalCaches();
    storage.map.remove(_findBundleForSource(bundles, aSource).id);
    expect(cache.getLibraryClosureBundles(testSource), isNull);
  }

  void test_getLibraryClosureBundles_importSdk() {
    putTestLibrary(r'''
import 'dart:async';
main() {}
''');
    List<LibraryBundleWithId> bundles =
        cache.getLibraryClosureBundles(testSource);
    expect(bundles, isNotNull);
    expect(_getBundleSources(bundles), [testSource].toSet());
  }

  void test_getLibraryClosureBundles_onlyLibrary() {
    putTestLibrary(r'''
main() {}
''');
    // the cache is empty, no bundles
    List<LibraryBundleWithId> bundles =
        cache.getLibraryClosureBundles(testSource);
    expect(bundles, isNotNull);
  }

  void test_getSourceKind_library() {
    putTestLibrary(r'''
main() {}
''');
    expect(cache.getSourceKind(testSource), SourceKind.LIBRARY);
  }

  void test_getSourceKind_library_usedAsPart() {
    verifyNoTestUnitErrors = false;
    Source fooSource = addSource(
        '/foo.dart',
        r'''
import 'dart:math';
''');
    putTestLibrary(r'''
part 'foo.dart';
main() {}
''');
    expect(cache.getSourceKind(testSource), SourceKind.LIBRARY);
    // not a part, but also not enough information to write it as a library
    expect(cache.getSourceKind(fooSource), isNull);
  }

  void test_getSourceKind_notCached() {
    resolveTestUnit(r'''
main() {}
''');
    expect(cache.getSourceKind(testSource), isNull);
  }

  void test_getSourceKind_part() {
    Source partSource = addSource('/foo.dart', 'part of lib;');
    putTestLibrary(r'''
library lib;
part 'foo.dart';
''');
    expect(cache.getSourceKind(testSource), SourceKind.LIBRARY);
    expect(cache.getSourceKind(partSource), SourceKind.PART);
  }

  LibraryBundleWithId _findBundleForSource(
      List<LibraryBundleWithId> bundles, Source source) {
    return bundles.singleWhere((b) => b.source == source);
  }

  Set<Source> _getBundleSources(List<LibraryBundleWithId> bundles) {
    return bundles.map((b) => b.source).toSet();
  }
}

/**
 * A [Map] based [CacheStorage].
 */
class _TestCacheStorage implements CacheStorage {
  final Map<String, List<int>> map = <String, List<int>>{};

  @override
  List<int> get(String key) {
    return map[key];
  }

  @override
  void put(String key, List<int> bytes) {
    map[key] = bytes;
  }
}
