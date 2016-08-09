// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/pub_summary.dart';
import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart' hide ERROR;

import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(PubSummaryManagerTest);
}

@reflectiveTest
class PubSummaryManagerTest extends AbstractContextTest {
  PubSummaryManager manager;

  void setUp() {
    super.setUp();
    manager = new PubSummaryManager(resourceProvider, '_.temp');
  }

  test_getUnlinkedBundles() async {
    // Create package files.
    String cachePath = '/home/.pub-cache/hosted/pub.dartlang.org';
    resourceProvider.newFile(
        '$cachePath/aaa/lib/a.dart',
        '''
class A {}
''');
    resourceProvider.newFile(
        '$cachePath/aaa/lib/src/a2.dart',
        '''
class A2 {}
''');
    resourceProvider.newFile(
        '$cachePath/bbb/lib/b.dart',
        '''
class B {}
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$cachePath/aaa/lib');
    Folder libFolderB = resourceProvider.newFolder('$cachePath/bbb/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
      })
    ]);

    // No unlinked bundles yet.
    {
      Map<String, PackageBundle> bundles = manager.getUnlinkedBundles(context);
      expect(bundles, isEmpty);
    }

    // The requested unlinked bundles must be available after the wait.
    await manager.onUnlinkedComplete;
    {
      Map<String, PackageBundle> bundles = manager.getUnlinkedBundles(context);
      expect(bundles, hasLength(2));
      {
        PackageBundle bundle = bundles['aaa'];
        expect(bundle.linkedLibraryUris, isEmpty);
        expect(bundle.unlinkedUnitUris,
            ['package:aaa/a.dart', 'package:aaa/src/a2.dart']);
        expect(bundle.unlinkedUnits, hasLength(2));
        expect(bundle.unlinkedUnits[0].classes.map((c) => c.name), ['A']);
        expect(bundle.unlinkedUnits[1].classes.map((c) => c.name), ['A2']);
      }
      {
        PackageBundle bundle = bundles['bbb'];
        expect(bundle.linkedLibraryUris, isEmpty);
        expect(bundle.unlinkedUnitUris, ['package:bbb/b.dart']);
        expect(bundle.unlinkedUnits, hasLength(1));
        expect(bundle.unlinkedUnits[0].classes.map((c) => c.name), ['B']);
      }
    }

    // The files must be created.
    File fileA = libFolderA.parent.getChildAssumingFile('unlinked.ds');
    File fileB = libFolderB.parent.getChildAssumingFile('unlinked.ds');
    expect(fileA.exists, isTrue);
    expect(fileB.exists, isTrue);
  }

  test_getUnlinkedBundles_nullPackageMap() async {
    context.sourceFactory =
        new SourceFactory(<UriResolver>[sdkResolver, resourceResolver]);
    Map<String, PackageBundle> bundles = manager.getUnlinkedBundles(context);
    expect(bundles, isEmpty);
  }

  test_isPathInPubCache_posix() {
    expect(
        PubSummaryManager.isPathInPubCache(pathos.posix,
            '/home/.pub-cache/hosted/pub.dartlang.org/foo/lib/bar.dart'),
        isTrue);
    expect(
        PubSummaryManager.isPathInPubCache(
            pathos.posix, '/home/.pub-cache/foo/lib/bar.dart'),
        isTrue);
    expect(
        PubSummaryManager.isPathInPubCache(
            pathos.posix, '/home/sources/dart/foo/lib/bar.dart'),
        isFalse);
  }

  test_isPathInPubCache_windows() {
    expect(
        PubSummaryManager.isPathInPubCache(pathos.windows,
            r'C:\Users\user\Setters\Pub\Cache\hosted\foo\lib\bar.dart'),
        isTrue);
    expect(
        PubSummaryManager.isPathInPubCache(
            pathos.windows, r'C:\Users\user\Sources\Dart\foo\lib\bar.dart'),
        isFalse);
  }
}
