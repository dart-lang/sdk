// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/pub_summary.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
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
  static const String CACHE = '/home/.pub-cache/hosted/pub.dartlang.org';

  static Map<DartSdk, PackageBundle> sdkBundleMap = <DartSdk, PackageBundle>{};

  PubSummaryManager manager;

  void setUp() {
    super.setUp();
    manager = new PubSummaryManager(resourceProvider, '_.temp');
  }

  test_getLinkedBundles_noCycles() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
class A {}
int a;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:aaa/a.dart';
A b;
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$CACHE/aaa/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
      })
    ]);

    // Ensure unlinked bundles.
    manager.getUnlinkedBundles(context);
    await manager.onUnlinkedComplete;

    // Now we should be able to get linked bundles.
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, hasLength(2));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      PackageBundle unlinked = linkedPackage.unlinked;
      PackageBundle linked = linkedPackage.linked;
      expect(unlinked, isNotNull);
      expect(linked, isNotNull);
      expect(unlinked.unlinkedUnitUris, ['package:aaa/a.dart']);
      expect(linked.linkedLibraryUris, ['package:aaa/a.dart']);
      // Prepare linked `package:aaa/a.dart`.
      UnlinkedUnit unlinkedUnitA = unlinked.unlinkedUnits[0];
      LinkedLibrary linkedLibraryA = linked.linkedLibraries[0];
      LinkedUnit linkedUnitA = linkedLibraryA.units[0];
      // int a;
      {
        UnlinkedVariable a = unlinkedUnitA.variables[0];
        expect(a.name, 'a');
        _assertLinkedNameReference(unlinkedUnitA, linkedLibraryA, linkedUnitA,
            a.type.reference, 'int', 'dart:core');
      }
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      PackageBundle unlinked = linkedPackage.unlinked;
      PackageBundle linked = linkedPackage.linked;
      expect(unlinked, isNotNull);
      expect(linked, isNotNull);
      expect(unlinked.unlinkedUnitUris, ['package:bbb/b.dart']);
      expect(linked.linkedLibraryUris, ['package:bbb/b.dart']);
      // Prepare linked `package:bbb/b.dart`.
      UnlinkedUnit unlinkedUnit = unlinked.unlinkedUnits[0];
      LinkedLibrary linkedLibrary = linked.linkedLibraries[0];
      LinkedUnit linkedUnit = linkedLibrary.units[0];
      // A b;
      {
        UnlinkedVariable b = unlinkedUnit.variables[0];
        expect(b.name, 'b');
        _assertLinkedNameReference(unlinkedUnit, linkedLibrary, linkedUnit,
            b.type.reference, 'A', 'package:aaa/a.dart');
      }
    }
  }

  test_getUnlinkedBundles() async {
    // Create package files.
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
class A {}
''');
    resourceProvider.newFile(
        '$CACHE/aaa/lib/src/a2.dart',
        '''
class A2 {}
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
class B {}
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$CACHE/aaa/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
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
      Map<PubPackage, PackageBundle> bundles =
          manager.getUnlinkedBundles(context);
      expect(bundles, isEmpty);
    }

    // The requested unlinked bundles must be available after the wait.
    await manager.onUnlinkedComplete;
    {
      Map<PubPackage, PackageBundle> bundles =
          manager.getUnlinkedBundles(context);
      expect(bundles, hasLength(2));
      {
        PackageBundle bundle = _getBundleByPackageName(bundles, 'aaa');
        expect(bundle.linkedLibraryUris, isEmpty);
        expect(bundle.unlinkedUnitUris,
            ['package:aaa/a.dart', 'package:aaa/src/a2.dart']);
        expect(bundle.unlinkedUnits, hasLength(2));
        expect(bundle.unlinkedUnits[0].classes.map((c) => c.name), ['A']);
        expect(bundle.unlinkedUnits[1].classes.map((c) => c.name), ['A2']);
      }
      {
        PackageBundle bundle = _getBundleByPackageName(bundles, 'bbb');
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
    Map<PubPackage, PackageBundle> bundles =
        manager.getUnlinkedBundles(context);
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

  void _assertLinkedNameReference(
      UnlinkedUnit unlinkedUnit,
      LinkedLibrary linkedLibrary,
      LinkedUnit linkedUnit,
      int typeNameReference,
      String expectedName,
      String expectedDependencyUri) {
    expect(unlinkedUnit.references[typeNameReference].name, expectedName);
    int typeNameDependency =
        linkedUnit.references[typeNameReference].dependency;
    expect(linkedLibrary.dependencies[typeNameDependency].uri,
        expectedDependencyUri);
  }

  /**
   * Compute element based summary bundle for the given [sdk].
   */
  static PackageBundle getSdkBundle(DartSdk sdk) {
    return sdkBundleMap.putIfAbsent(sdk, () {
      PackageBundleAssembler assembler = new PackageBundleAssembler();
      for (SdkLibrary sdkLibrary in sdk.sdkLibraries) {
        String uriStr = sdkLibrary.shortName;
        Source source = sdk.mapDartUri(uriStr);
        LibraryElement libraryElement =
            sdk.context.computeLibraryElement(source);
        assembler.serializeLibraryElement(libraryElement);
      }
      List<int> bytes = assembler.assemble().toBuffer();
      return new PackageBundle.fromBuffer(bytes);
    });
  }

  static PackageBundle _getBundleByPackageName(
      Map<PubPackage, PackageBundle> bundles, String name) {
    PubPackage package =
        bundles.keys.singleWhere((package) => package.name == name);
    return bundles[package];
  }
}
