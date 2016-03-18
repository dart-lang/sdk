// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
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

  @override
  void setUp() {
    super.setUp();
    cache = new IncrementalCache(storage, context, <int>[]);
  }

  void test_getSourceKind_library() {
    resolveTestUnit(r'''
main() {}
''');
    cache.putLibrary(testLibraryElement);
    expect(cache.getSourceKind(testSource), SourceKind.LIBRARY);
  }

  void test_getSourceKind_library_usedAsPart() {
    verifyNoTestUnitErrors = false;
    Source fooSource = addSource(
        '/foo.dart',
        r'''
import 'dart:math';
''');
    resolveTestUnit(r'''
part 'foo.dart';
main() {}
''');
    cache.putLibrary(testLibraryElement);
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
    resolveTestUnit(r'''
library lib;
part 'foo.dart';
''');
    cache.putLibrary(testLibraryElement);
    expect(cache.getSourceKind(testSource), SourceKind.LIBRARY);
    expect(cache.getSourceKind(partSource), SourceKind.PART);
  }

  void test_readBundle_emptyCache() {
    resolveTestUnit('main() {}');
    // the cache is empty, no bundle
    PackageBundle bundle = cache.readBundle(testSource);
    expect(bundle, isNull);
  }

  void test_readBundle_exportLib() {
    addSource('/a.dart', '// 1');
    resolveTestUnit(r'''
export 'a.dart';
main() {}
''');
    cache.putLibrary(testLibraryElement);
    // has bundle
    expect(cache.readBundle(testSource), isNotNull);
    // update a.dart, no bundle
    cache.clearInternalCaches();
    resourceProvider.updateFile('/a.dart', '// 2');
    expect(cache.readBundle(testSource), isNull);
  }

  void test_readBundle_importLib() {
    addSource('/a.dart', '// 1');
    resolveTestUnit(r'''
import 'a.dart';
main() {}
''');
    cache.putLibrary(testLibraryElement);
    // has bundle
    expect(cache.readBundle(testSource), isNotNull);
    // update a.dart, no bundle
    cache.clearInternalCaches();
    resourceProvider.updateFile('/a.dart', '// 2');
    expect(cache.readBundle(testSource), isNull);
  }

  void test_readBundle_importSdk() {
    resolveTestUnit(r'''
import 'dart:async';
main() {}
''');
    cache.putLibrary(testLibraryElement);
    // has bundle
    PackageBundle bundle = cache.readBundle(testSource);
    expect(bundle, isNotNull);
  }

  void test_readBundle_withoutDependencies() {
    resolveTestUnit('main() {}');
    cache.putLibrary(testLibraryElement);
    // has bundle
    PackageBundle bundle = cache.readBundle(testSource);
    expect(bundle, isNotNull);
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
