// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

/// TODO(paulberry): this logic is duplicated from other packages.  Find a way
/// share it, or avoid relying on it.
class AbstractContextTest with ResourceProviderMixin {
  OverlayResourceProvider overlayResourceProvider;

  AnalysisContextCollection _analysisContextCollection;
  AnalysisDriver _driver;

  AnalysisDriver get driver => _driver;

  String get homePath => '/home';

  AnalysisSession get session => driver.currentSession;

  String get testsPath => '$homePath/tests';

  void addMetaPackage() {
    addPackageFile('meta', 'meta.dart', r'''
library meta;

const Required required = const Required();

class Required {
  final String reason;
  const Required([this.reason]);
}
''');
  }

  /// Add a new file with the given [pathInLib] to the package with the given
  /// [packageName].  Then ensure that the package under test depends on the
  /// package.
  File addPackageFile(String packageName, String pathInLib, String content) {
    var packagePath = '/.pub-cache/$packageName';
    _addTestPackageDependency(packageName, packagePath);
    return newFile('$packagePath/lib/$pathInLib', content: content);
  }

  /// Add the quiver package and a library with URI,
  /// "package:quiver/check.dart".
  ///
  /// Then ensure that the package under test depends on the package.
  void addQuiverPackage() {
    addPackageFile('quiver', 'check.dart', r'''
library quiver.check;

T checkNotNull<T>(T reference, {dynamic message}) => T;
''');
  }

  Source addSource(String path, String content, [Uri uri]) {
    File file = newFile(path, content: content);
    Source source = file.createSource(uri);
    driver.addFile(file.path);
    driver.changeFile(file.path);
    return source;
  }

  /// Add the test_core package and a library with URI,
  /// "package:test_core/test_core.dart".
  ///
  /// Then ensure that the package under test depends on the package.
  void addTestCorePackage() {
    addPackageFile('test_core', 'test_core.dart', r'''
library test_core;

void setUp(dynamic callback()) {}
void group(dynamic description, dynamic body()) {}
void test(dynamic description, dynamic body()) {}
''');
    addPackageFile('test', 'test.dart', r'''
library test;
export 'package:test_core/test_core.dart';
''');
  }

  /// Create all analysis contexts in [_homePath].
  void createAnalysisContexts() {
    _analysisContextCollection = AnalysisContextCollectionImpl(
      includedPaths: [convertPath(homePath)],
      enableIndex: true,
      resourceProvider: overlayResourceProvider,
      sdkPath: convertPath('/sdk'),
    );

    _driver = getDriver(convertPath(testsPath));
  }

  /// Return the existing analysis context that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisContext getContext(String path) {
    path = convertPath(path);
    return _analysisContextCollection.contextFor(path);
  }

  /// Return the existing analysis driver that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisDriver getDriver(String path) {
    DriverBasedAnalysisContext context =
        getContext(path) as DriverBasedAnalysisContext;
    return context.driver;
  }

  LineInfo getLineInfo(String path) => session.getFile(path).lineInfo;

  void setUp() {
    setupResourceProvider();
    overlayResourceProvider = OverlayResourceProvider(resourceProvider);

    MockSdk(resourceProvider: resourceProvider);

    newFolder(testsPath);
    newFile('$testsPath/.packages', content: '''
tests:file://$testsPath/lib
''');
    var pubspecPath = '$testsPath/pubspec.yaml';
    // Subclasses may write out a different file first.
    if (!getFile(pubspecPath).exists) {
      newFile(pubspecPath, content: '''
name: tests
version: 1.0.0
environment:
  sdk: '>=2.9.0 <3.0.0'
''');
    }
    var packageConfigPath = '$testsPath/.dart_tool/package_config.json';
    // Subclasses may write out a different file first.
    if (!getFile(packageConfigPath).exists) {
      // TODO(srawlins): This is a rough hack to allow for the "null safe by
      // default" flag flip. We need to _opt out_ all packages at the onset.
      // A better solution likely involves the package config-editing code in
      // analyzer's [context_collection_resolution.dart].
      newFile(packageConfigPath, content: '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "args",
      "rootUri": "${toUriStr('/.pub-cache/args')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "collection",
      "rootUri": "${toUriStr('/.pub-cache/collection')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "fixnum",
      "rootUri": "${toUriStr('/.pub-cache/fixnum')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "foo",
      "rootUri": "${toUriStr('/.pub-cache/foo')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "http",
      "rootUri": "${toUriStr('/.pub-cache/http')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "meta",
      "rootUri": "${toUriStr('/.pub-cache/meta')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "quiver",
      "rootUri": "${toUriStr('/.pub-cache/quiver')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "test",
      "rootUri": "${toUriStr('/.pub-cache/test')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "test_core",
      "rootUri": "${toUriStr('/.pub-cache/test_core')}",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    },
    {
      "name": "tests",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.9"
    }
  ],
  "generated": "2020-10-21T21:13:05.186004Z",
  "generator": "pub",
  "generatorVersion": "2.10.0"
}
''');
    }

    createAnalysisContexts();
  }

  void setupResourceProvider() {}

  void tearDown() {
    AnalysisEngine.instance.clearCaches();
  }

  void _addTestPackageDependency(String name, String rootPath) {
    var packagesFile = getFile('$testsPath/.packages');
    var packagesContent = packagesFile.readAsStringSync();

    // Ignore if there is already the same package dependency.
    if (packagesContent.contains('$name:file://')) {
      return;
    }

    packagesContent += '$name:${toUri('$rootPath/lib')}\n';

    packagesFile.writeAsStringSync(packagesContent);

    _createDriver();
  }

  void _createDriver() {
    var collection = AnalysisContextCollectionImpl(
      includedPaths: [convertPath(homePath)],
      enableIndex: true,
      resourceProvider: resourceProvider,
      sdkPath: convertPath('/sdk'),
    );

    var testPath = convertPath(testsPath);
    var context = collection.contextFor(testPath) as DriverBasedAnalysisContext;

    _driver = context.driver;
  }
}
