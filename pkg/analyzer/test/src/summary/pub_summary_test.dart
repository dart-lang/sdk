// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/pub_summary.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart' hide ERROR;

import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';
import '../context/mock_sdk.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(PubSummaryManagerTest);
}

@reflectiveTest
class PubSummaryManagerTest extends AbstractContextTest {
  static const String CACHE = '/home/.pub-cache/hosted/pub.dartlang.org';

  PubSummaryManager manager;

  void setUp() {
    super.setUp();
    _createManager();
  }

  test_computeSdkExtension() async {
    // Create package files.
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
class A {}
''');
    resourceProvider.newFile(
        '$CACHE/aaa/sdk_ext/extA.dart',
        '''
library test.a;
import 'dart:async';
part 'src/p1.dart';
part 'src/p2.dart';
class ExtA {}
int V0;
''');
    resourceProvider.newFile(
        '$CACHE/aaa/sdk_ext/src/p1.dart',
        '''
part of test.a;
class ExtAA {}
double V1;
''');
    resourceProvider.newFile(
        '$CACHE/aaa/sdk_ext/src/p2.dart',
        '''
part of test.a;
class ExtAB {}
Future V2;
''');
    resourceProvider.newFile(
        '$CACHE/aaa/lib/_sdkext',
        '''
{
  "dart:aaa.internal": "../sdk_ext/extA.dart"
}
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

    PackageBundle sdkBundle = sdk.getLinkedBundle();
    PackageBundle bundle = manager.computeSdkExtension(context, sdkBundle);
    expect(bundle, isNotNull);
    expect(bundle.linkedLibraryUris, ['dart:aaa.internal']);
    expect(bundle.unlinkedUnitUris, [
      'dart:aaa.internal',
      'dart:aaa.internal/src/p1.dart',
      'dart:aaa.internal/src/p2.dart'
    ]);
    expect(bundle.unlinkedUnits, hasLength(3));
    expect(bundle.unlinkedUnits[0].classes.map((c) => c.name), ['ExtA']);
    expect(bundle.unlinkedUnits[1].classes.map((c) => c.name), ['ExtAA']);
    expect(bundle.unlinkedUnits[2].classes.map((c) => c.name), ['ExtAB']);
    // The library is linked.
    expect(bundle.linkedLibraries, hasLength(1));
    LinkedLibrary linkedLibrary = bundle.linkedLibraries[0];
    // V0 is linked
    {
      UnlinkedUnit unlinkedUnit = bundle.unlinkedUnits[0];
      LinkedUnit linkedUnit = linkedLibrary.units[0];
      expect(unlinkedUnit.variables, hasLength(1));
      UnlinkedVariable variable = unlinkedUnit.variables[0];
      expect(variable.name, 'V0');
      int typeRef = variable.type.reference;
      expect(unlinkedUnit.references[typeRef].name, 'int');
      LinkedReference linkedReference = linkedUnit.references[typeRef];
      expect(linkedLibrary.dependencies[linkedReference.dependency].uri,
          'dart:core');
    }
    // V1 is linked
    {
      UnlinkedUnit unlinkedUnit = bundle.unlinkedUnits[1];
      LinkedUnit linkedUnit = linkedLibrary.units[1];
      expect(unlinkedUnit.variables, hasLength(1));
      UnlinkedVariable variable = unlinkedUnit.variables[0];
      expect(variable.name, 'V1');
      int typeRef = variable.type.reference;
      expect(unlinkedUnit.references[typeRef].name, 'double');
      LinkedReference linkedReference = linkedUnit.references[typeRef];
      expect(linkedLibrary.dependencies[linkedReference.dependency].uri,
          'dart:core');
    }
    // V2 is linked
    {
      UnlinkedUnit unlinkedUnit = bundle.unlinkedUnits[2];
      LinkedUnit linkedUnit = linkedLibrary.units[2];
      expect(unlinkedUnit.variables, hasLength(1));
      UnlinkedVariable variable = unlinkedUnit.variables[0];
      expect(variable.name, 'V2');
      int typeRef = variable.type.reference;
      expect(unlinkedUnit.references[typeRef].name, 'Future');
      LinkedReference linkedReference = linkedUnit.references[typeRef];
      expect(linkedLibrary.dependencies[linkedReference.dependency].uri,
          'dart:async');
    }
  }

  test_computeUnlinkedForFolder() async {
    // Create package files.
    resourceProvider.newFile(
        '/flutter/aaa/lib/a.dart',
        '''
class A {}
''');
    resourceProvider.newFile(
        '/flutter/bbb/lib/b.dart',
        '''
class B {}
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('/flutter/aaa/lib');
    Folder libFolderB = resourceProvider.newFolder('/flutter/bbb/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
      })
    ]);

    await manager.computeUnlinkedForFolder('aaa', libFolderA);
    await manager.computeUnlinkedForFolder('bbb', libFolderB);

    // The files must be created.
    _assertFileExists(libFolderA.parent, PubSummaryManager.UNLINKED_NAME);
    _assertFileExists(libFolderA.parent, PubSummaryManager.UNLINKED_SPEC_NAME);
    _assertFileExists(libFolderB.parent, PubSummaryManager.UNLINKED_NAME);
    _assertFileExists(libFolderB.parent, PubSummaryManager.UNLINKED_SPEC_NAME);
  }

  test_getLinkedBundles_cached() async {
    String pathA1 = '$CACHE/aaa-1.0.0';
    String pathA2 = '$CACHE/aaa-2.0.0';
    resourceProvider.newFile(
        '$pathA1/lib/a.dart',
        '''
class A {}
int a;
''');
    resourceProvider.newFile(
        '$pathA2/lib/a.dart',
        '''
class A2 {}
int a;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:aaa/a.dart';
A b;
''');
    Folder folderA1 = resourceProvider.getFolder(pathA1);
    Folder folderA2 = resourceProvider.getFolder(pathA2);
    Folder folderB = resourceProvider.getFolder('$CACHE/bbb');

    // Configure packages resolution.
    Folder libFolderA1 = resourceProvider.newFolder('$pathA1/lib');
    Folder libFolderA2 = resourceProvider.newFolder('$pathA2/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA1],
        'bbb': [libFolderB],
      })
    ]);

    // Session 1.
    // Create linked bundles and store them in files.
    String linkedHashA;
    String linkedHashB;
    {
      // Ensure unlinked bundles.
      manager.getUnlinkedBundles(context);
      await manager.onUnlinkedComplete;

      // Now we should be able to get linked bundles.
      List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
      expect(linkedPackages, hasLength(2));

      // Verify that files with linked bundles were created.
      LinkedPubPackage packageA = _getLinkedPackage(linkedPackages, 'aaa');
      LinkedPubPackage packageB = _getLinkedPackage(linkedPackages, 'bbb');
      linkedHashA = packageA.linkedHash;
      linkedHashB = packageB.linkedHash;
      _assertFileExists(folderA1, 'linked_spec_$linkedHashA.ds');
      _assertFileExists(folderB, 'linked_spec_$linkedHashB.ds');
    }

    // Session 2.
    // Recreate manager and ask again.
    {
      _createManager();
      List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
      expect(linkedPackages, hasLength(2));

      // Verify that linked packages have the same hashes, so they must
      // be have been read from the previously created files.
      LinkedPubPackage packageA = _getLinkedPackage(linkedPackages, 'aaa');
      LinkedPubPackage packageB = _getLinkedPackage(linkedPackages, 'bbb');
      expect(packageA.linkedHash, linkedHashA);
      expect(packageB.linkedHash, linkedHashB);
    }

    // Session 2 with different 'aaa' version.
    // Different linked bundles.
    {
      context.sourceFactory = new SourceFactory(<UriResolver>[
        sdkResolver,
        resourceResolver,
        new PackageMapUriResolver(resourceProvider, {
          'aaa': [libFolderA2],
          'bbb': [libFolderB],
        })
      ]);

      // Ensure unlinked bundles.
      manager.getUnlinkedBundles(context);
      await manager.onUnlinkedComplete;

      // Now we should be able to get linked bundles.
      List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
      expect(linkedPackages, hasLength(2));

      // Verify that new files with linked bundles were created.
      LinkedPubPackage packageA = _getLinkedPackage(linkedPackages, 'aaa');
      LinkedPubPackage packageB = _getLinkedPackage(linkedPackages, 'bbb');
      expect(packageA.linkedHash, isNot(linkedHashA));
      expect(packageB.linkedHash, isNot(linkedHashB));
      _assertFileExists(folderA2, 'linked_spec_${packageA.linkedHash}.ds');
      _assertFileExists(folderB, 'linked_spec_${packageB.linkedHash}.ds');
    }
  }

  test_getLinkedBundles_cached_differentSdk() async {
    String pathA = '$CACHE/aaa';
    resourceProvider.newFile(
        '$pathA/lib/a.dart',
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
    Folder folderA = resourceProvider.getFolder(pathA);
    Folder folderB = resourceProvider.getFolder('$CACHE/bbb');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$pathA/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
      })
    ]);

    // Session 1.
    // Create linked bundles and store them in files.
    String linkedHashA;
    String linkedHashB;
    {
      // Ensure unlinked bundles.
      manager.getUnlinkedBundles(context);
      await manager.onUnlinkedComplete;

      // Now we should be able to get linked bundles.
      List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
      expect(linkedPackages, hasLength(2));

      // Verify that files with linked bundles were created.
      LinkedPubPackage packageA = _getLinkedPackage(linkedPackages, 'aaa');
      LinkedPubPackage packageB = _getLinkedPackage(linkedPackages, 'bbb');
      linkedHashA = packageA.linkedHash;
      linkedHashB = packageB.linkedHash;
      _assertFileExists(folderA, 'linked_spec_$linkedHashA.ds');
      _assertFileExists(folderB, 'linked_spec_$linkedHashB.ds');
    }

    // Session 2.
    // Use DartSdk with a different API signature.
    // Different linked bundles should be created.
    {
      MockSdk sdk = new MockSdk();
      sdk.updateUriFile('dart:math', (String content) {
        return content + '  class NewMathClass {}';
      });
      context.sourceFactory = new SourceFactory(<UriResolver>[
        new DartUriResolver(sdk),
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
      List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
      expect(linkedPackages, hasLength(2));

      // Verify that new files with linked bundles were created.
      LinkedPubPackage packageA = _getLinkedPackage(linkedPackages, 'aaa');
      LinkedPubPackage packageB = _getLinkedPackage(linkedPackages, 'bbb');
      expect(packageA.linkedHash, isNot(linkedHashA));
      expect(packageB.linkedHash, isNot(linkedHashB));
      _assertFileExists(folderA, 'linked_spec_${packageA.linkedHash}.ds');
      _assertFileExists(folderB, 'linked_spec_${packageB.linkedHash}.ds');
    }
  }

  test_getLinkedBundles_cached_useSdkExtension() async {
    String pathA1 = '$CACHE/aaa-1.0.0';
    String pathA2 = '$CACHE/aaa-2.0.0';
    // aaa-1.0.0
    resourceProvider.newFile(
        '$pathA1/lib/a.dart',
        '''
class A {}
int a;
''');
    resourceProvider.newFile(
        '$pathA1/sdk_ext/extA.dart',
        '''
class ExtA1 {}
''');
    resourceProvider.newFile(
        '$pathA1/lib/_sdkext',
        '''
{
  "dart:aaa": "../sdk_ext/extA.dart"
}
''');
    // aaa-2.0.0
    resourceProvider.newFile(
        '$pathA2/lib/a.dart',
        '''
class A {}
int a;
''');
    resourceProvider.newFile(
        '$pathA2/sdk_ext/extA.dart',
        '''
class ExtA2 {}
''');
    resourceProvider.newFile(
        '$pathA2/lib/_sdkext',
        '''
{
  "dart:aaa": "../sdk_ext/extA.dart"
}
''');
    // bbb
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:aaa/a.dart';
A b;
''');
    Folder folderA1 = resourceProvider.getFolder(pathA1);
    Folder folderA2 = resourceProvider.getFolder(pathA2);
    Folder folderB = resourceProvider.getFolder('$CACHE/bbb');

    // Configure packages resolution.
    Folder libFolderA1 = resourceProvider.newFolder('$pathA1/lib');
    Folder libFolderA2 = resourceProvider.newFolder('$pathA2/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA1],
        'bbb': [libFolderB],
      })
    ]);

    // Session 1.
    // Create linked bundles and store them in files.
    String linkedHashA;
    String linkedHashB;
    {
      // Ensure unlinked bundles.
      manager.getUnlinkedBundles(context);
      await manager.onUnlinkedComplete;

      // Now we should be able to get linked bundles.
      List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
      expect(linkedPackages, hasLength(2));

      // Verify that files with linked bundles were created.
      LinkedPubPackage packageA = _getLinkedPackage(linkedPackages, 'aaa');
      LinkedPubPackage packageB = _getLinkedPackage(linkedPackages, 'bbb');
      linkedHashA = packageA.linkedHash;
      linkedHashB = packageB.linkedHash;
      _assertFileExists(folderA1, 'linked_spec_$linkedHashA.ds');
      _assertFileExists(folderB, 'linked_spec_$linkedHashB.ds');
    }

    // Session 2.
    // Use 'aaa-2.0.0', with a different SDK extension.
    {
      context.sourceFactory = new SourceFactory(<UriResolver>[
        sdkResolver,
        resourceResolver,
        new PackageMapUriResolver(resourceProvider, {
          'aaa': [libFolderA2],
          'bbb': [libFolderB],
        })
      ]);

      // Ensure unlinked bundles.
      manager.getUnlinkedBundles(context);
      await manager.onUnlinkedComplete;

      // Now we should be able to get linked bundles.
      List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
      expect(linkedPackages, hasLength(2));

      // Verify that new files with linked bundles were created.
      LinkedPubPackage packageA = _getLinkedPackage(linkedPackages, 'aaa');
      LinkedPubPackage packageB = _getLinkedPackage(linkedPackages, 'bbb');
      expect(packageA.linkedHash, isNot(linkedHashA));
      expect(packageB.linkedHash, isNot(linkedHashB));
      _assertFileExists(folderA2, 'linked_spec_${packageA.linkedHash}.ds');
      _assertFileExists(folderB, 'linked_spec_${packageB.linkedHash}.ds');
    }
  }

  test_getLinkedBundles_hasCycle() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'package:bbb/b.dart';
class A {}
int a1;
B a2;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:ccc/c.dart';
class B {}
C b;
''');
    resourceProvider.newFile(
        '$CACHE/ccc/lib/c.dart',
        '''
import 'package:aaa/a.dart';
import 'package:ddd/d.dart';
class C {}
A c1;
D c2;
''');
    resourceProvider.newFile(
        '$CACHE/ddd/lib/d.dart',
        '''
class D {}
String d;
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$CACHE/aaa/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    Folder libFolderC = resourceProvider.newFolder('$CACHE/ccc/lib');
    Folder libFolderD = resourceProvider.newFolder('$CACHE/ddd/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
        'ccc': [libFolderC],
        'ddd': [libFolderD],
      })
    ]);

    // Ensure unlinked bundles.
    manager.getUnlinkedBundles(context);
    await manager.onUnlinkedComplete;

    // Now we should be able to get linked bundles.
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(4));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      expect(linkedPackage.linked.linkedLibraryUris, ['package:aaa/a.dart']);
      _assertHasLinkedVariable(linkedPackage, 'a1', 'int',
          expectedTypeNameUri: 'dart:core');
      _assertHasLinkedVariable(linkedPackage, 'a2', 'B',
          expectedTypeNameUri: 'package:bbb/b.dart');
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      expect(linkedPackage.linked.linkedLibraryUris, ['package:bbb/b.dart']);
      _assertHasLinkedVariable(linkedPackage, 'b', 'C',
          expectedTypeNameUri: 'package:ccc/c.dart');
    }

    // package:ccc
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'ccc');
      expect(linkedPackage.linked.linkedLibraryUris, ['package:ccc/c.dart']);
      _assertHasLinkedVariable(linkedPackage, 'c1', 'A',
          expectedTypeNameUri: 'package:aaa/a.dart');
      _assertHasLinkedVariable(linkedPackage, 'c2', 'D',
          expectedTypeNameUri: 'package:ddd/d.dart');
    }

    // package:ddd
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'ddd');
      expect(linkedPackage.linked.linkedLibraryUris, ['package:ddd/d.dart']);
      _assertHasLinkedVariable(linkedPackage, 'd', 'String',
          expectedTypeNameUri: 'dart:core');
    }
  }

  test_getLinkedBundles_missingBundle() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
int a;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:ccc/c.dart';
int b1;
C b2;
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

    // Try to link.
    // Both 'aaa' and 'bbb' are linked.
    // The name 'C' in 'b.dart' is not resolved.
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(2));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'int',
          expectedTypeNameUri: 'dart:core');
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      _assertHasLinkedVariable(linkedPackage, 'b1', 'int',
          expectedTypeNameUri: 'dart:core');
      _assertHasLinkedVariable(linkedPackage, 'b2', 'C',
          expectedToBeResolved: false);
    }
  }

  test_getLinkedBundles_missingBundle_chained() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'package:bbb/b.dart';
int a1;
B a2;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:ccc/c.dart';
class B {}
int b1;
C b2;
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

    // Try to link.
    // Both 'aaa' and 'bbb' are linked.
    // The name 'C' in 'b.dart' is not resolved.
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(2));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a1', 'int',
          expectedTypeNameUri: 'dart:core');
      _assertHasLinkedVariable(linkedPackage, 'a2', 'B',
          expectedTypeNameUri: 'package:bbb/b.dart');
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      _assertHasLinkedVariable(linkedPackage, 'b1', 'int',
          expectedTypeNameUri: 'dart:core');
      _assertHasLinkedVariable(linkedPackage, 'b2', 'C',
          expectedToBeResolved: false);
    }
  }

  test_getLinkedBundles_missingLibrary() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'package:bbb/b2.dart';
int a1;
B2 a2;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
class B {}
int b = 42;
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

    // Try to link.
    // Both 'aaa' and 'bbb' are linked.
    // The name 'B2' in 'a.dart' is not resolved.
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(2));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a1', 'int',
          expectedTypeNameUri: 'dart:core');
      _assertHasLinkedVariable(linkedPackage, 'a2', 'B2',
          expectedToBeResolved: false);
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      _assertHasLinkedVariable(linkedPackage, 'b', 'int',
          expectedTypeNameUri: 'dart:core');
    }
  }

  test_getLinkedBundles_missingLibrary_hasCycle() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'package:bbb/b.dart';
B a;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:aaa/a.dart';
import 'package:ccc/c2.dart';
class B {}
int b1;
C2 b2;
''');
    resourceProvider.newFile(
        '$CACHE/ccc/lib/c.dart',
        '''
class C {}
int c;
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$CACHE/aaa/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    Folder libFolderC = resourceProvider.newFolder('$CACHE/ccc/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
        'ccc': [libFolderC],
      })
    ]);

    // Ensure unlinked bundles.
    manager.getUnlinkedBundles(context);
    await manager.onUnlinkedComplete;

    // Try to link.
    // All bundles 'aaa' and 'bbb' and 'ccc' are linked.
    // The name 'C2' in 'b.dart' is not resolved.
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(3));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'B',
          expectedTypeNameUri: 'package:bbb/b.dart');
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      _assertHasLinkedVariable(linkedPackage, 'b1', 'int',
          expectedTypeNameUri: 'dart:core');
      _assertHasLinkedVariable(linkedPackage, 'b2', 'C2',
          expectedToBeResolved: false);
    }

    // package:ccc
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'ccc');
      _assertHasLinkedVariable(linkedPackage, 'c', 'int',
          expectedTypeNameUri: 'dart:core');
    }
  }

  test_getLinkedBundles_noCycle() async {
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
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(2));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'int',
          expectedTypeNameUri: 'dart:core');
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      _assertHasLinkedVariable(linkedPackage, 'b', 'A',
          expectedTypeNameUri: 'package:aaa/a.dart');
    }
  }

  test_getLinkedBundles_noCycle_relativeUri() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'src/a2.dart';
A a;
''');
    resourceProvider.newFile(
        '$CACHE/aaa/lib/src/a2.dart',
        '''
class A {}
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$CACHE/aaa/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
      })
    ]);

    // Ensure unlinked bundles.
    manager.getUnlinkedBundles(context);
    await manager.onUnlinkedComplete;

    // Link.
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(1));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'A',
          expectedTypeNameUri: 'src/a2.dart');
    }
  }

  test_getLinkedBundles_noCycle_withExport() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'package:bbb/b.dart';
C a;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
export 'package:ccc/c.dart';
''');
    resourceProvider.newFile(
        '$CACHE/ccc/lib/c.dart',
        '''
class C {}
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$CACHE/aaa/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    Folder libFolderC = resourceProvider.newFolder('$CACHE/ccc/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
        'ccc': [libFolderC],
      })
    ]);

    // Ensure unlinked bundles.
    manager.getUnlinkedBundles(context);
    await manager.onUnlinkedComplete;

    // Now we should be able to get linked bundles.
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(3));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'C',
          expectedTypeNameUri: 'package:ccc/c.dart');
    }
  }

  test_getLinkedBundles_useSdkExtension() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'dart:bbb';
ExtB a;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'dart:bbb';
ExtB b;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/sdk_ext/extB.dart',
        '''
class ExtB {}
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/_sdkext',
        '''
{
  "dart:bbb": "../sdk_ext/extB.dart"
}
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
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(2));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'ExtB',
          expectedTypeNameUri: 'dart:bbb');
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      _assertHasLinkedVariable(linkedPackage, 'b', 'ExtB',
          expectedTypeNameUri: 'dart:bbb');
    }
  }

  test_getLinkedBundles_wrongScheme() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'xxx:yyy/zzz.dart';
int a1;
Z a2;
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.newFolder('$CACHE/aaa/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
      })
    ]);

    // Ensure unlinked bundles.
    manager.getUnlinkedBundles(context);
    await manager.onUnlinkedComplete;

    // Try to link.
    // The package 'aaa' is linked.
    // The name 'Z' in 'a.dart' is not resolved.
    List<LinkedPubPackage> linkedPackages = manager.getLinkedBundles(context);
    expect(linkedPackages, hasLength(1));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a1', 'int',
          expectedTypeNameUri: 'dart:core');
      _assertHasLinkedVariable(linkedPackage, 'a2', 'Z',
          expectedToBeResolved: false);
    }
  }

  test_getPackageName() {
    String getPackageName(String uriStr) {
      return PubSummaryManager.getPackageName(uriStr);
    }
    expect(getPackageName('package:foo/bar.dart'), 'foo');
    expect(getPackageName('package:foo/bar/baz.dart'), 'foo');
    expect(getPackageName('wrong:foo/bar.dart'), isNull);
    expect(getPackageName('package:foo'), isNull);
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
    _assertFileExists(libFolderA.parent, PubSummaryManager.UNLINKED_NAME);
    _assertFileExists(libFolderA.parent, PubSummaryManager.UNLINKED_SPEC_NAME);
    _assertFileExists(libFolderB.parent, PubSummaryManager.UNLINKED_NAME);
    _assertFileExists(libFolderB.parent, PubSummaryManager.UNLINKED_SPEC_NAME);
  }

  test_getUnlinkedBundles_notPubCache_dontCreate() async {
    String aaaPath = '/Users/user/projects/aaa';
    // Create package files.
    resourceProvider.newFile(
        '$aaaPath/lib/a.dart',
        '''
class A {}
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
class B {}
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.getFolder('$aaaPath/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
      })
    ]);

    // No unlinked bundles initially.
    {
      Map<PubPackage, PackageBundle> bundles =
          manager.getUnlinkedBundles(context);
      expect(bundles, isEmpty);
    }

    // Wait for unlinked bundles to be computed.
    await manager.onUnlinkedComplete;
    Map<PubPackage, PackageBundle> bundles =
        manager.getUnlinkedBundles(context);
    // We have just one bundle - for 'bbb'.
    expect(bundles, hasLength(1));
    // We computed the unlinked bundle for 'bbb'.
    {
      PackageBundle bundle = _getBundleByPackageName(bundles, 'bbb');
      expect(bundle.linkedLibraryUris, isEmpty);
      expect(bundle.unlinkedUnitUris, ['package:bbb/b.dart']);
      expect(bundle.unlinkedUnits, hasLength(1));
      expect(bundle.unlinkedUnits[0].classes.map((c) => c.name), ['B']);
    }

    // The files must be created.
    _assertFileExists(libFolderB.parent, PubSummaryManager.UNLINKED_NAME);
    _assertFileExists(libFolderB.parent, PubSummaryManager.UNLINKED_SPEC_NAME);
  }

  test_getUnlinkedBundles_notPubCache_useExisting() async {
    String aaaPath = '/Users/user/projects/aaa';
    // Create package files.
    {
      File file = resourceProvider.newFile(
          '$aaaPath/lib/a.dart',
          '''
class A {}
''');
      PackageBundleAssembler assembler = new PackageBundleAssembler()
        ..addUnlinkedUnit(
            file.createSource(FastUri.parse('package:aaa/a.dart')),
            new UnlinkedUnitBuilder());
      resourceProvider.newFileWithBytes(
          '$aaaPath/${PubSummaryManager.UNLINKED_SPEC_NAME}',
          assembler.assemble().toBuffer());
    }
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
class B {}
''');

    // Configure packages resolution.
    Folder libFolderA = resourceProvider.getFolder('$aaaPath/lib');
    Folder libFolderB = resourceProvider.newFolder('$CACHE/bbb/lib');
    context.sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new PackageMapUriResolver(resourceProvider, {
        'aaa': [libFolderA],
        'bbb': [libFolderB],
      })
    ]);

    // Request already available unlinked bundles.
    {
      Map<PubPackage, PackageBundle> bundles =
          manager.getUnlinkedBundles(context);
      expect(bundles, hasLength(1));
      // We get the unlinked bundle for 'aaa' because it already exists.
      {
        PackageBundle bundle = _getBundleByPackageName(bundles, 'aaa');
        expect(bundle, isNotNull);
      }
    }

    // Wait for unlinked bundles to be computed.
    await manager.onUnlinkedComplete;
    Map<PubPackage, PackageBundle> bundles =
        manager.getUnlinkedBundles(context);
    expect(bundles, hasLength(2));
    // We still have the unlinked bundle for 'aaa'.
    {
      PackageBundle bundle = _getBundleByPackageName(bundles, 'aaa');
      expect(bundle, isNotNull);
    }
    // We computed the unlinked bundle for 'bbb'.
    {
      PackageBundle bundle = _getBundleByPackageName(bundles, 'bbb');
      expect(bundle.linkedLibraryUris, isEmpty);
      expect(bundle.unlinkedUnitUris, ['package:bbb/b.dart']);
      expect(bundle.unlinkedUnits, hasLength(1));
      expect(bundle.unlinkedUnits[0].classes.map((c) => c.name), ['B']);
    }

    // The files must be created.
    _assertFileExists(libFolderB.parent, PubSummaryManager.UNLINKED_NAME);
    _assertFileExists(libFolderB.parent, PubSummaryManager.UNLINKED_SPEC_NAME);
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

  void _assertFileExists(Folder folder, String fileName) {
    expect(folder.getChildAssumingFile(fileName).exists, isTrue);
  }

  void _assertHasLinkedVariable(LinkedPubPackage linkedPackage,
      String variableName, String expectedTypeName,
      {bool expectedToBeResolved: true,
      String expectedTypeNameUri: 'shouldBeSpecifiedIfResolved'}) {
    PackageBundle unlinked = linkedPackage.unlinked;
    PackageBundle linked = linkedPackage.linked;
    expect(unlinked, isNotNull);
    expect(linked, isNotNull);
    for (int i = 0; i < unlinked.unlinkedUnitUris.length; i++) {
      String unlinkedUnitUri = unlinked.unlinkedUnitUris[i];
      UnlinkedUnit unlinkedUnit = unlinked.unlinkedUnits[i];
      for (UnlinkedVariable v in unlinkedUnit.variables) {
        if (v.name == variableName) {
          int typeNameReference = v.type.reference;
          expect(unlinkedUnit.references[typeNameReference].name,
              expectedTypeName);
          for (int j = 0; j < linked.linkedLibraryUris.length; j++) {
            String linkedLibraryUri = linked.linkedLibraryUris[j];
            if (linkedLibraryUri == unlinkedUnitUri) {
              LinkedLibrary linkedLibrary = linked.linkedLibraries[j];
              LinkedUnit linkedUnit = linkedLibrary.units.single;
              int typeNameDependency =
                  linkedUnit.references[typeNameReference].dependency;
              if (expectedToBeResolved) {
                expect(linkedLibrary.dependencies[typeNameDependency].uri,
                    expectedTypeNameUri);
              } else {
                expect(typeNameDependency, isZero);
              }
              return;
            }
          }
          fail('Cannot find linked unit for $variableName in $linkedPackage');
        }
      }
    }
    fail('Cannot find variable $variableName in $linkedPackage');
  }

  void _createManager() {
    manager = new PubSummaryManager(resourceProvider, '_.temp');
  }

  LinkedPubPackage _getLinkedPackage(
      List<LinkedPubPackage> packages, String name) {
    return packages
        .singleWhere((linkedPackage) => linkedPackage.package.name == name);
  }

  static PackageBundle _getBundleByPackageName(
      Map<PubPackage, PackageBundle> bundles, String name) {
    PubPackage package =
        bundles.keys.singleWhere((package) => package.name == name);
    return bundles[package];
  }
}
