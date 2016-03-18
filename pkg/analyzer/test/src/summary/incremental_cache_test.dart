// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/incremental_cache.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../abstract_single_unit.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LibraryBundleCacheTest);
}

/**
 * TODO(scheglov) write more tests for invalidation.
 */
@reflectiveTest
class LibraryBundleCacheTest extends AbstractSingleUnitTest {
  Folder cacheFolder;
  LibraryBundleCache cache;

  @override
  void setUp() {
    super.setUp();
    cacheFolder = resourceProvider.newFolder('/cache');
    cache = new LibraryBundleCache('pid.tmp', cacheFolder, context, <int>[]);
  }

  void test_readBundle_emptyCache() {
    resolveTestUnit('main() {}');
    // the cache is empty, no bundle
    PackageBundle bundle = cache.readBundle(testSource);
    expect(bundle, isNull);
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

  void test_readBundle_withoutDependencies() {
    resolveTestUnit('main() {}');
    cache.putLibrary(testLibraryElement);
    // has bundle
    PackageBundle bundle = cache.readBundle(testSource);
    expect(bundle, isNotNull);
  }
}
