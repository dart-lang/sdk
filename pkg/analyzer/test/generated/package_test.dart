// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.package_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/package.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:package_config/packages.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../src/context/mock_sdk.dart';
import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(DependencyFinderTest);
  runReflectiveTests(PackageDescriptionTest);
  runReflectiveTests(PackageManagerTest);
}

/**
 * The name of the pubspec.yaml file.
 */
const String pubspecName = 'pubspec.yaml';

@reflectiveTest
class DependencyFinderTest extends ResolverTestCase {
  /**
   * The resource provider to be used by tests.
   */
  MemoryResourceProvider resourceProvider;

  @override
  void setUp() {
    resourceProvider = new MemoryResourceProvider();
  }

  void test_transitiveDependenciesFor_circularDependencies() {
    String packageA = '/pub-cache/a-1.0';
    String packageB = '/pub-cache/b-1.0';
    String packageC = '/pub-cache/c-1.0';
    resourceProvider.newFile(
        '$packageA/$pubspecName',
        '''
    dependencies:
      b: any
    ''');
    resourceProvider.newFile(
        '$packageB/$pubspecName',
        '''
    dependencies:
      c: any
    ''');
    resourceProvider.newFile(
        '$packageC/$pubspecName',
        '''
    dependencies:
      a: any
    ''');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[resourceProvider.getFolder(packageA)],
      'b': <Folder>[resourceProvider.getFolder(packageB)],
      'c': <Folder>[resourceProvider.getFolder(packageC)],
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> result =
        finder.transitiveDependenciesFor(packageMap, packageA);
    expect(result, unorderedEquals([packageB, packageC]));
  }

  void test_transitiveDependenciesFor_missingPubspec() {
    String packagePath = '/pub-cache/a-1.0';
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[resourceProvider.getFolder(packagePath)]
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    expect(() => finder.transitiveDependenciesFor(packageMap, packagePath),
        throws);
  }

  void test_transitiveDependenciesFor_noDependencies() {
    String packagePath = '/pub-cache/a-1.0';
    resourceProvider.newFile('$packagePath/$pubspecName', '');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[resourceProvider.getFolder(packagePath)]
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> result =
        finder.transitiveDependenciesFor(packageMap, packagePath);
    expect(result, hasLength(0));
  }

  void test_transitiveDependenciesFor_overlappingDependencies() {
    String packageA = '/pub-cache/a-1.0';
    String packageB = '/pub-cache/b-1.0';
    String packageC = '/pub-cache/c-1.0';
    String packageD = '/pub-cache/d-1.0';
    resourceProvider.newFile(
        '$packageA/$pubspecName',
        '''
    dependencies:
      b: any
      c: any
    ''');
    resourceProvider.newFile(
        '$packageB/$pubspecName',
        '''
    dependencies:
      d: any
    ''');
    resourceProvider.newFile(
        '$packageC/$pubspecName',
        '''
    dependencies:
      d: any
    ''');
    resourceProvider.newFile('$packageD/$pubspecName', '');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[resourceProvider.getFolder(packageA)],
      'b': <Folder>[resourceProvider.getFolder(packageB)],
      'c': <Folder>[resourceProvider.getFolder(packageC)],
      'd': <Folder>[resourceProvider.getFolder(packageD)],
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> result =
        finder.transitiveDependenciesFor(packageMap, packageA);
    expect(result, unorderedEquals([packageB, packageC, packageD]));
  }

  void test_transitiveDependenciesFor_simpleDependencies() {
    String packageA = '/pub-cache/a-1.0';
    String packageB = '/pub-cache/b-1.0';
    String packageC = '/pub-cache/c-1.0';
    resourceProvider.newFile(
        '$packageA/$pubspecName',
        '''
    dependencies:
      b: any
      c: any
    ''');
    resourceProvider.newFile('$packageB/$pubspecName', '');
    resourceProvider.newFile('$packageC/$pubspecName', '');
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'a': <Folder>[resourceProvider.getFolder(packageA)],
      'b': <Folder>[resourceProvider.getFolder(packageB)],
      'c': <Folder>[resourceProvider.getFolder(packageC)],
    };

    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> result =
        finder.transitiveDependenciesFor(packageMap, packageA);
    expect(result, unorderedEquals([packageB, packageC]));
  }
}

@reflectiveTest
class PackageDescriptionTest extends ResolverTestCase {
  void test_equal_false_differentOptions() {
    String packageId = 'path1;path2';
    DartSdk sdk = new MockSdk();
    AnalysisOptionsImpl options1 = new AnalysisOptionsImpl();
    AnalysisOptionsImpl options2 = new AnalysisOptionsImpl();
    options2.enableAsync = !options1.enableAsync;
    PackageDescription first = new PackageDescription(packageId, sdk, options1);
    PackageDescription second =
        new PackageDescription(packageId, sdk, options2);
    expect(first == second, isFalse);
  }

  void test_equal_false_differentPaths() {
    String packageId1 = 'path1;path2';
    String packageId2 = 'path1;path3';
    DartSdk sdk = new MockSdk();
    AnalysisOptions options = new AnalysisOptionsImpl();
    PackageDescription first = new PackageDescription(packageId1, sdk, options);
    PackageDescription second =
        new PackageDescription(packageId2, sdk, options);
    expect(first == second, isFalse);
  }

  void test_equal_false_differentSdks() {
    String packageId = 'path1;path2';
    DartSdk sdk1 = new MockSdk();
    DartSdk sdk2 = new MockSdk();
    AnalysisOptions options = new AnalysisOptionsImpl();
    PackageDescription first = new PackageDescription(packageId, sdk1, options);
    PackageDescription second =
        new PackageDescription(packageId, sdk2, options);
    expect(first == second, isFalse);
  }

  void test_equal_true() {
    String packageId = 'path1;path2';
    DartSdk sdk = new MockSdk();
    AnalysisOptions options = new AnalysisOptionsImpl();
    PackageDescription first = new PackageDescription(packageId, sdk, options);
    PackageDescription second = new PackageDescription(packageId, sdk, options);
    expect(first == second, isTrue);
  }
}

@reflectiveTest
class PackageManagerTest extends ResolverTestCase {
  /**
   * The resource provider to be used by tests.
   */
  MemoryResourceProvider resourceProvider;

  @override
  void setUp() {
    resourceProvider = new MemoryResourceProvider();
  }

  void test_getContext() {
    String packageA = '/pub-cache/a-1.0';
    String packageB1 = '/pub-cache/b-1.0';
    String packageB2 = '/pub-cache/b-2.0';
    String packageC = '/pub-cache/c-1.0';
    resourceProvider.newFile(
        '$packageA/$pubspecName',
        '''
    dependencies:
      b: any
      c: any
    ''');
    resourceProvider.newFile('$packageB1/$pubspecName', '');
    resourceProvider.newFile('$packageB2/$pubspecName', '');
    resourceProvider.newFile('$packageC/$pubspecName', '');

    Packages packages1 = new _MockPackages(<String, Uri>{
      'a': new Uri.file(packageA),
      'b': new Uri.file(packageB1),
      'c': new Uri.file(packageC),
    });
    DartUriResolver resolver = new DartUriResolver(new MockSdk());
    AnalysisOptions options = new AnalysisOptionsImpl();
    //
    // Verify that we can compute a context for a package.
    //
    PackageManager manager = new PackageManager(resourceProvider);
    AnalysisContext context1 =
        manager.getContext(packageA, packages1, resolver, options);
    expect(context1, isNotNull);
    //
    // Verify that if we have the same package map we get the same context.
    //
    AnalysisContext context2 =
        manager.getContext(packageA, packages1, resolver, options);
    expect(context2, same(context1));
    //
    // Verify that if we have a different package map we get a different context.
    //
    Packages packages3 = new _MockPackages(<String, Uri>{
      'a': new Uri.file(packageA),
      'b': new Uri.file(packageB2),
      'c': new Uri.file(packageC),
    });
    AnalysisContext context3 =
        manager.getContext(packageA, packages3, resolver, options);
    expect(context3, isNot(same(context1)));
  }
}

/**
 * An implementation of [Packages] used for testing.
 */
class _MockPackages implements Packages {
  final Map<String, Uri> map;

  _MockPackages(this.map);

  @override
  Iterable<String> get packages => map.keys;

  @override
  Map<String, Uri> asMap() => map;

  @override
  Uri resolve(Uri packageUri, {Uri notFound(Uri packageUri)}) {
    fail('Unexpected invocation of resolve');
    return null;
  }
}
