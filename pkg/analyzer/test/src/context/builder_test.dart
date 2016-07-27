// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.context.context_builder_test;

import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import '../../utils.dart';
import 'mock_sdk.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(ContextBuilderTest_WithDisk);
  runReflectiveTests(ContextBuilderTest_WithoutDisk);
}

@reflectiveTest
class ContextBuilderTest_WithDisk extends EngineTestCase {
  /**
   * The resource provider to be used by tests.
   */
  PhysicalResourceProvider resourceProvider;

  /**
   * The path context used to manipulate file paths.
   */
  path.Context pathContext;

  /**
   * The SDK manager used by the tests;
   */
  DartSdkManager sdkManager;

  /**
   * The content cache used by the tests.
   */
  ContentCache contentCache;

  @override
  void setUp() {
    resourceProvider = PhysicalResourceProvider.INSTANCE;
    pathContext = resourceProvider.pathContext;
    sdkManager = new DartSdkManager('', false, (_) => new MockSdk());
    contentCache = new ContentCache();
  }

  void test_createPackageMap_fromPackageDirectory_explicit() {
    withTempDir((io.Directory tempDir) {
      // Use a package directory that is outside the project directory.
      String rootPath = tempDir.path;
      String projectPath = pathContext.join(rootPath, 'project');
      String packageDirPath = pathContext.join(rootPath, 'packages');
      String fooName = 'foo';
      String fooPath = pathContext.join(packageDirPath, fooName);
      String barName = 'bar';
      String barPath = pathContext.join(packageDirPath, barName);
      new io.Directory(projectPath).createSync(recursive: true);
      new io.Directory(fooPath).createSync(recursive: true);
      new io.Directory(barPath).createSync(recursive: true);

      ContextBuilder builder =
          new ContextBuilder(resourceProvider, sdkManager, contentCache);
      builder.defaultPackagesDirectoryPath = packageDirPath;

      Packages packages = builder.createPackageMap(projectPath);
      expect(packages, isNotNull);
      Map<String, Uri> map = packages.asMap();
      expect(map, hasLength(2));
      expect(map[fooName], new Uri.directory(fooPath));
      expect(map[barName], new Uri.directory(barPath));
    });
  }

  void test_createPackageMap_fromPackageDirectory_inRoot() {
    withTempDir((io.Directory tempDir) {
      // Use a package directory that is inside the project directory.
      String projectPath = tempDir.path;
      String packageDirPath = pathContext.join(projectPath, 'packages');
      String fooName = 'foo';
      String fooPath = pathContext.join(packageDirPath, fooName);
      String barName = 'bar';
      String barPath = pathContext.join(packageDirPath, barName);
      new io.Directory(fooPath).createSync(recursive: true);
      new io.Directory(barPath).createSync(recursive: true);

      ContextBuilder builder =
          new ContextBuilder(resourceProvider, sdkManager, contentCache);
      Packages packages = builder.createPackageMap(projectPath);
      expect(packages, isNotNull);
      Map<String, Uri> map = packages.asMap();
      expect(map, hasLength(2));
      expect(map[fooName], new Uri.directory(fooPath));
      expect(map[barName], new Uri.directory(barPath));
    });
  }

  void test_createPackageMap_fromPackageFile_explicit() {
    withTempDir((io.Directory tempDir) {
      // Use a package file that is outside the project directory's hierarchy.
      String rootPath = tempDir.path;
      String projectPath = pathContext.join(rootPath, 'project');
      String packageFilePath = pathContext.join(rootPath, 'child', '.packages');
      new io.Directory(projectPath).createSync(recursive: true);
      new io.File(packageFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
foo:/pkg/foo
bar:/pkg/bar
''');

      ContextBuilder builder =
          new ContextBuilder(resourceProvider, sdkManager, contentCache);
      builder.defaultPackageFilePath = packageFilePath;
      Packages packages = builder.createPackageMap(projectPath);
      expect(packages, isNotNull);
      Map<String, Uri> map = packages.asMap();
      expect(map, hasLength(2));
      expect(map['foo'], new Uri.directory('/pkg/foo'));
      expect(map['bar'], new Uri.directory('/pkg/bar'));
    });
  }

  void test_createPackageMap_fromPackageFile_inParentOfRoot() {
    withTempDir((io.Directory tempDir) {
      // Use a package file that is inside the parent of the project directory.
      String rootPath = tempDir.path;
      String projectPath = pathContext.join(rootPath, 'project');
      String packageFilePath = pathContext.join(rootPath, '.packages');
      new io.Directory(projectPath).createSync(recursive: true);
      new io.File(packageFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
foo:/pkg/foo
bar:/pkg/bar
''');

      ContextBuilder builder =
          new ContextBuilder(resourceProvider, sdkManager, contentCache);
      Packages packages = builder.createPackageMap(projectPath);
      expect(packages, isNotNull);
      Map<String, Uri> map = packages.asMap();
      expect(map, hasLength(2));
      expect(map['foo'], new Uri.directory('/pkg/foo'));
      expect(map['bar'], new Uri.directory('/pkg/bar'));
    });
  }

  void test_createPackageMap_fromPackageFile_inRoot() {
    withTempDir((io.Directory tempDir) {
      // Use a package file that is inside the project directory.
      String rootPath = tempDir.path;
      String projectPath = pathContext.join(rootPath, 'project');
      String packageFilePath = pathContext.join(projectPath, '.packages');
      new io.Directory(projectPath).createSync(recursive: true);
      new io.File(packageFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
foo:/pkg/foo
bar:/pkg/bar
''');

      ContextBuilder builder =
          new ContextBuilder(resourceProvider, sdkManager, contentCache);
      Packages packages = builder.createPackageMap(projectPath);
      expect(packages, isNotNull);
      Map<String, Uri> map = packages.asMap();
      expect(map, hasLength(2));
      expect(map['foo'], new Uri.directory('/pkg/foo'));
      expect(map['bar'], new Uri.directory('/pkg/bar'));
    });
  }

  void test_createPackageMap_none() {
    withTempDir((io.Directory tempDir) {
      ContextBuilder builder =
          new ContextBuilder(resourceProvider, sdkManager, contentCache);
      Packages packages = builder.createPackageMap(tempDir.path);
      expect(packages, same(Packages.noPackages));
    });
  }

  /**
   * Execute the [test] function with a temporary [directory]. The test function
   * can perform any disk operations within the directory and the directory (and
   * its content) will be removed after the function returns.
   */
  void withTempDir(test(io.Directory directory)) {
    io.Directory directory =
        io.Directory.systemTemp.createTempSync('analyzer_');
    try {
      test(directory);
    } finally {
      directory.deleteSync(recursive: true);
    }
  }
}

@reflectiveTest
class ContextBuilderTest_WithoutDisk extends EngineTestCase {
  /**
   * The resource provider to be used by tests.
   */
  MemoryResourceProvider resourceProvider;

  /**
   * The SDK manager used by the tests;
   */
  DartSdkManager sdkManager;

  /**
   * The content cache used by the tests.
   */
  ContentCache contentCache;

  void fail_createSourceFactory() {
    fail('Incomplete test');
  }

  void fail_findSdkResolver() {
    fail('Incomplete test');
  }

  @override
  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    sdkManager = new DartSdkManager('', false, (_) => new MockSdk());
    contentCache = new ContentCache();
  }

  void test_convertPackagesToMap_noPackages() {
    ContextBuilder builder =
        new ContextBuilder(resourceProvider, sdkManager, contentCache);
    expect(builder.convertPackagesToMap(Packages.noPackages), isNull);
  }

  void test_convertPackagesToMap_null() {
    ContextBuilder builder =
        new ContextBuilder(resourceProvider, sdkManager, contentCache);
    expect(builder.convertPackagesToMap(null), isNull);
  }

  void test_convertPackagesToMap_packages() {
    String fooName = 'foo';
    String fooPath = '/pkg/foo';
    Uri fooUri = new Uri.directory(fooPath);
    String barName = 'bar';
    String barPath = '/pkg/bar';
    Uri barUri = new Uri.directory(barPath);

    ContextBuilder builder =
        new ContextBuilder(resourceProvider, sdkManager, contentCache);
    MapPackages packages = new MapPackages({fooName: fooUri, barName: barUri});
    Map<String, List<Folder>> result = builder.convertPackagesToMap(packages);
    expect(result, isNotNull);
    expect(result, hasLength(2));
    expect(result[fooName], hasLength(1));
    expect(result[fooName][0].path, fooPath);
    expect(result[barName], hasLength(1));
    expect(result[barName][0].path, barPath);
  }

  void test_getOptionsFile_explicit() {
    String path = '/some/directory/path';
    String filePath = '/options/analysis.yaml';
    resourceProvider.newFile(filePath, '');

    ContextBuilder builder =
        new ContextBuilder(resourceProvider, sdkManager, contentCache);
    builder.defaultAnalysisOptionsFilePath = filePath;
    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inParentOfRoot_new() {
    String parentPath = '/some/directory';
    String path = '$parentPath/path';
    String filePath =
        '$parentPath/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}';
    resourceProvider.newFile(filePath, '');

    ContextBuilder builder =
        new ContextBuilder(resourceProvider, sdkManager, contentCache);
    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inParentOfRoot_old() {
    String parentPath = '/some/directory';
    String path = '$parentPath/path';
    String filePath = '$parentPath/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}';
    resourceProvider.newFile(filePath, '');

    ContextBuilder builder =
        new ContextBuilder(resourceProvider, sdkManager, contentCache);
    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inRoot_new() {
    String path = '/some/directory/path';
    String filePath = '$path/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}';
    resourceProvider.newFile(filePath, '');

    ContextBuilder builder =
        new ContextBuilder(resourceProvider, sdkManager, contentCache);
    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inRoot_old() {
    String path = '/some/directory/path';
    String filePath = '$path/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}';
    resourceProvider.newFile(filePath, '');

    ContextBuilder builder =
        new ContextBuilder(resourceProvider, sdkManager, contentCache);
    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }
}
