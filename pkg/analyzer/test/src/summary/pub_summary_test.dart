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

    PackageBundle sdkBundle = getSdkBundle(sdk);
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
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, hasLength(4));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      expect(linkedPackage.linked.linkedLibraryUris, ['package:aaa/a.dart']);
      _assertHasLinkedVariable(linkedPackage, 'a1', 'int', 'dart:core');
      _assertHasLinkedVariable(linkedPackage, 'a2', 'B', 'package:bbb/b.dart');
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      expect(linkedPackage.linked.linkedLibraryUris, ['package:bbb/b.dart']);
      _assertHasLinkedVariable(linkedPackage, 'b', 'C', 'package:ccc/c.dart');
    }

    // package:ccc
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'ccc');
      expect(linkedPackage.linked.linkedLibraryUris, ['package:ccc/c.dart']);
      _assertHasLinkedVariable(linkedPackage, 'c1', 'A', 'package:aaa/a.dart');
      _assertHasLinkedVariable(linkedPackage, 'c2', 'D', 'package:ddd/d.dart');
    }

    // package:ddd
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'ddd');
      expect(linkedPackage.linked.linkedLibraryUris, ['package:ddd/d.dart']);
      _assertHasLinkedVariable(linkedPackage, 'd', 'String', 'dart:core');
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
C b;
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
    // Only 'aaa' can be linked, because 'bbb' references not available 'ccc'.
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, hasLength(1));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'int', 'dart:core');
    }
  }

  test_getLinkedBundles_missingBundle_chained() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'package:bbb/b.dart';
int a;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:ccc/c.dart';
int b;
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
    // No linked libraries, because 'aaa' needs 'bbb', and 'bbb' needs 'ccc'.
    // But 'ccc' is not available, so the whole chain cannot be linked.
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, isEmpty);
  }

  test_getLinkedBundles_missingLibrary() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'package:bbb/b2.dart';
int a;
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
    // Only 'bbb', because 'aaa' references 'package:bbb/b2.dart', which does
    // not exist in the bundle 'bbb'.
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, hasLength(1));

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      _assertHasLinkedVariable(linkedPackage, 'b', 'int', 'dart:core');
    }
  }

  test_getLinkedBundles_missingLibrary_hasCycle() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'package:bbb/b.dart';
int a;
''');
    resourceProvider.newFile(
        '$CACHE/bbb/lib/b.dart',
        '''
import 'package:aaa/a.dart';
import 'package:ccc/c2.dart';
class B {}
int b;
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
    // Only 'ccc' is linked.
    // The 'aaa' + 'bbb' cycle cannot be linked because 'bbb' references
    // 'package:ccc/c2.dart', which does not exist in the bundle 'ccc'.
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, hasLength(1));

    // package:ccc
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'ccc');
      _assertHasLinkedVariable(linkedPackage, 'c', 'int', 'dart:core');
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
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, hasLength(2));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'int', 'dart:core');
    }

    // package:bbb
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'bbb');
      _assertHasLinkedVariable(linkedPackage, 'b', 'A', 'package:aaa/a.dart');
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
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, hasLength(1));

    // package:aaa
    {
      LinkedPubPackage linkedPackage = linkedPackages
          .singleWhere((linkedPackage) => linkedPackage.package.name == 'aaa');
      _assertHasLinkedVariable(linkedPackage, 'a', 'A', 'src/a2.dart');
    }
  }

  test_getLinkedBundles_wrongScheme() async {
    resourceProvider.newFile(
        '$CACHE/aaa/lib/a.dart',
        '''
import 'xxx:yyy/zzz.dart';
Z a;
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
    // The package 'aaa' cannot be linked because it uses not 'dart' or
    // 'package' import URI scheme.
    PackageBundle sdkBundle = getSdkBundle(sdk);
    List<LinkedPubPackage> linkedPackages =
        manager.getLinkedBundles(context, sdkBundle);
    expect(linkedPackages, hasLength(0));
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

  void _assertHasLinkedVariable(
      LinkedPubPackage linkedPackage,
      String variableName,
      String expectedTypeName,
      String expectedTypeNameUri) {
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
              expect(linkedLibrary.dependencies[typeNameDependency].uri,
                  expectedTypeNameUri);
              return;
            }
          }
          fail('Cannot find linked unit for $variableName in $linkedPackage');
        }
      }
    }
    fail('Cannot find variable $variableName in $linkedPackage');
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
