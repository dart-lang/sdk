// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverForPackageBuildTest);
  });
}

@reflectiveTest
class AnalysisDriverForPackageBuildTest with ResourceProviderMixin {
  File get testFile => getFile('$testPackageLibPath/test.dart');

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  void setUp() {
    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newPackageConfigJsonFileFromBuilder(
      testPackageRootPath,
      PackageConfigFileBuilder()
        ..add(
          name: 'test',
          rootPath: testPackageRootPath,
        ),
    );
  }

  test_currentSession_afterChangeFile() async {
    var analysisDriver = await _createAnalysisDriver();
    var analysisSession = analysisDriver.currentSession;

    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    analysisDriver.changeFile(a.path);

    var unitResult = await analysisSession.getResolvedUnit(a.path);
    unitResult as ResolvedUnitResult;
  }

  test_currentSession_getResolvedUnit() async {
    var analysisDriver = await _createAnalysisDriver();
    var analysisSession = analysisDriver.currentSession;

    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var unitResult = await analysisSession.getResolvedUnit(a.path);
    unitResult as ResolvedUnitResult;
    expect(unitResult.unit.declarations, hasLength(1));
  }

  test_sdkLibraryUris() async {
    var analysisDriver = await _createAnalysisDriver();

    expect(
      analysisDriver.sdkLibraryUris,
      containsAll([
        Uri.parse('dart:core'),
        Uri.parse('dart:async'),
        Uri.parse('dart:io'),
        Uri.parse('dart:_internal'),
      ]),
    );
  }

  /// Creates the driver for [testFile].
  Future<AnalysisDriverForPackageBuild> _createAnalysisDriver() async {
    var sdkRoot = getFolder('/sdk');

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    var sdkSummaryBytes = await buildSdkSummary(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );

    var packages = findPackagesFrom(resourceProvider, testFile);
    var uriResolver = _toPackageMapUriResolver(packages);

    var analysisDriver = createAnalysisDriver(
      resourceProvider: resourceProvider,
      sdkSummaryBytes: sdkSummaryBytes,
      analysisOptions: AnalysisOptionsImpl(),
      packages: packages,
      uriResolvers: [uriResolver],
    );
    return analysisDriver;
  }

  PackageMapUriResolver _toPackageMapUriResolver(Packages packages) {
    var map = <String, List<Folder>>{};
    for (var package in packages.packages) {
      map[package.name] = [package.libFolder];
    }
    return PackageMapUriResolver(resourceProvider, map);
  }
}
