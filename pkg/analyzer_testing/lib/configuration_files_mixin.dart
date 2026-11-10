// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/experiments.dart';
// ignore: implementation_imports
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';

/// A mixin adding functionality to write `.dart_tool/package_config.json`
/// files along with mock packages to a [ResourceProvider].
mixin ConfigurationFilesMixin on MockPackagesMixin {
  /// Adds the 'fixnum' package as a dependency to the package-under-test.
  bool get addFixnumPackageDep => false;

  /// Adds the 'flutter_localizations' package as a dependency to the
  /// package-under-test.
  bool get addFlutterLocalizationsPackageDep => false;

  /// Adds the 'flutter' package as a dependency to the package-under-test.
  bool get addFlutterPackageDep => false;

  /// Adds the 'flutter_test' package as a dependency to the
  /// package-under-test.
  bool get addFlutterTestPackageDep => false;

  /// Adds the 'meta' package as a dependency to the package-under-test.
  bool get addMetaPackageDep => false;

  /// Adds the 'test_reflective_loader' package as a dependency to the
  /// package-under-test.
  bool get addTestReflectiveLoaderPackageDep => false;

  /// Adds the 'vector_math' package as a dependency to the
  /// package-under-test.
  bool get addVectorMathPackageDep => false;

  String get dartSdkPath => resourceProvider.convertPath('/sdk');

  /// The Dart language version of the test package being used for testing.
  String? get testPackageLanguageVersion => _latestLanguageVersion;

  /// The path to the test package being used for testing.
  String get testPackageRootPath;

  String get _latestLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  /// Writes a package_config.json for the package at [projectFolderPath]. If
  /// [packageName] is not supplied, the last segment of [projectFolderPath] is
  /// used.
  void writePackageConfig2(
    String projectFolderPath, {
    // The name of this package. If not provided, the last segment of the path
    // will be used.
    String? packageName,
    PackageConfigFileBuilder? config,
    String? languageVersion,
  }) {
    projectFolderPath = resourceProvider.convertPath(projectFolderPath);

    if (config == null) {
      config = PackageConfigFileBuilder();
    } else {
      config = config.copy();
    }

    // Add this package to its own config.
    var effectivePackageName =
        packageName ?? pathContext.basename(projectFolderPath);
    if (!config.hasPackage(effectivePackageName)) {
      config.add(
        name: effectivePackageName,
        rootFolder: resourceProvider.getFolder(projectFolderPath),
        languageVersion: languageVersion ?? testPackageLanguageVersion,
      );
    }

    if (addFixnumPackageDep) {
      if (!config.hasPackage('fixnum')) {
        var fixnumPath = addFixnum().parent.path;
        config.add(
          name: 'fixnum',
          rootFolder: resourceProvider.getFolder(fixnumPath),
        );
      }
    }

    // flutter_test also depends on meta for @isTestGroup / @isTest
    if (addMetaPackageDep ||
        addFlutterPackageDep ||
        addFlutterTestPackageDep ||
        addMetaPackageDep) {
      if (!config.hasPackage('meta')) {
        var libFolder = addMeta();
        config.add(name: 'meta', rootFolder: libFolder.parent);
      }
    }

    if (addFlutterPackageDep) {
      if (!config.hasPackage('sky_engine')) {
        var skyEnginePath = addSkyEngine(sdkPath: dartSdkPath).parent.path;
        config.add(
          name: 'sky_engine',
          rootFolder: resourceProvider.getFolder(skyEnginePath),
        );
      }

      if (!config.hasPackage('flutter')) {
        var flutterLibFolder = addFlutter();
        config.add(name: 'flutter', rootFolder: flutterLibFolder.parent);
      }
    }

    if (addFlutterLocalizationsPackageDep) {
      if (!config.hasPackage('flutter_localizations')) {
        var libFolder = addFlutterLocalizations();
        config.add(name: 'flutter_localizations', rootFolder: libFolder.parent);
      }
    }

    if (addFlutterTestPackageDep) {
      if (!config.hasPackage('flutter_test')) {
        var flutterTestRootPath = resourceProvider.convertPath(
          '$packagesRootPath/flutter_test',
        );

        var flutterTestRoot = resourceProvider.getFolder(flutterTestRootPath);
        var libFolder = flutterTestRoot.getFolder('lib')..create();
        libFolder.getFile('flutter_test.dart').writeAsStringSync(r'''
import 'package:meta/meta.dart';

@isTest
void test(Object description, dynamic Function() body) {}

@isTestGroup
void group(Object description, void Function() body) {}

void main() {
  // Because this file is called 'flutter_test.dart' and is inside the 'test'
  // folder, it will be considered a test suite. To avoid it failing the bots
  // with "Invoked Dart programs must have a 'main' function defined", provide
  // an empty main function.
}

''');
        config.add(name: 'flutter_test', rootFolder: flutterTestRoot);
      }
    }

    if (addTestReflectiveLoaderPackageDep) {
      if (!config.hasPackage('test_reflective_loader')) {
        var testReflectiveLoaderPath = addTestReflectiveLoader().parent.path;
        config.add(
          name: 'test_reflective_loader',
          rootFolder: resourceProvider.getFolder(testReflectiveLoaderPath),
        );
      }
    }

    if (addVectorMathPackageDep) {
      if (!config.hasPackage('vector_math')) {
        var libFolder = addVectorMath();
        config.add(name: 'vector_math', rootFolder: libFolder.parent);
      }
    }

    var content = config.toContent();

    var projectFolder = resourceProvider.getFolder(projectFolderPath);
    var dartToolFolder = projectFolder.getFolder(file_paths.dotDartTool)
      ..create();
    dartToolFolder
        .getFile(file_paths.packageConfigJson)
        .writeAsStringSync(content);
  }

  /// Writes a package_config.json for the package under test (considered
  /// 'package:test') that lives in [testPackageRootPath].
  void writeTestPackageConfig2({
    PackageConfigFileBuilder? config,
    String? languageVersion,
  }) {
    writePackageConfig2(
      testPackageRootPath,
      config: config,
      languageVersion: languageVersion,
      packageName: 'test',
    );
  }
}
