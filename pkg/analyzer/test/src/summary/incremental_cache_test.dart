// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/incremental_cache.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import '../abstract_single_unit.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ComparePathsTest);
  runReflectiveTests(IncrementalCacheTest);
}

@reflectiveTest
class ComparePathsTest extends AbstractSingleUnitTest {
  void test_empty() {
    expect(comparePaths('', ''), 0);
  }

  void test_equal() {
    expect(comparePaths('abc', 'abc'), 0);
  }

  void test_longer_suffixAfter() {
    expect(comparePaths('aab', 'aa'), 1);
  }

  void test_longer_suffixBefore() {
    expect(comparePaths('aaa', 'ab'), -1);
  }

  void test_longer_suffixSame() {
    expect(comparePaths('aaa', 'aa'), 1);
  }

  void test_sameLength_before0() {
    expect(comparePaths('aaa', 'bbb'), -1);
  }

  void test_sameLength_before1() {
    expect(comparePaths('aaa', 'bba'), -1);
  }

  void test_sameLength_before2() {
    expect(comparePaths('aaa', 'bba'), -1);
  }

  void test_shorter_suffixAfter() {
    expect(comparePaths('ab', 'aaa'), 1);
  }

  void test_shorter_suffixBefore() {
    expect(comparePaths('aa', 'aab'), -1);
  }

  void test_shorter_suffixSame() {
    expect(comparePaths('aa', 'aaa'), -1);
  }
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

  void test_getLibraryParts_hasParts() {
    Source part1Source = addSource('/part1.dart', r'part of test;');
    Source part2Source = addSource('/part2.dart', r'part of test;');
    putTestLibrary(r'''
library test;
part 'part1.dart';
part 'part2.dart';
''');
    expect(cache.getLibraryParts(testSource),
        unorderedEquals([part1Source, part2Source]));
  }

  void test_getLibraryParts_noParts() {
    putTestLibrary(r'''
main() {}
''');
    expect(cache.getLibraryParts(testSource), isEmpty);
  }

  void test_getSourceErrorsInLibrary_library() {
    verifyNoTestUnitErrors = false;
    putTestLibrary(r'''
main() {
  int unusedVar = 42;
}
''');
    List<AnalysisError> computedErrors = context.computeErrors(testSource);
    cache.putSourceErrorsInLibrary(testSource, testSource, computedErrors);
    List<AnalysisError> readErrors =
        cache.getSourceErrorsInLibrary(testSource, testSource);
    new GatheringErrorListener()
      ..addAll(readErrors)
      ..assertErrors(computedErrors);
  }

  void test_getSourceErrorsInLibrary_part() {
    verifyNoTestUnitErrors = false;
    Source partSource = addSource(
        '/foo.dart',
        r'''
main() {
  int unusedVar = 42;
}
''');
    putTestLibrary(r'''
library lib;
part 'foo.dart';
''');
    List<AnalysisError> computedErrors = context.computeErrors(partSource);
    cache.putSourceErrorsInLibrary(testSource, partSource, computedErrors);
    List<AnalysisError> readErrors =
        cache.getSourceErrorsInLibrary(testSource, partSource);
    new GatheringErrorListener()
      ..addAll(readErrors)
      ..assertErrors(computedErrors);
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
  void compact() {}

  @override
  List<int> get(String key) {
    return map[key];
  }

  @override
  void put(String key, List<int> bytes) {
    map[key] = bytes;
  }
}
