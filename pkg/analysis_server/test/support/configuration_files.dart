// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_utilities/package_root.dart' as package_root;

import '../src/utilities/mock_packages.dart';

/// A mixin adding functionality to write `.dart_tool/package_config.json`
/// files along with mock packages to a [ResourceProvider].
mixin ConfigurationFilesMixin on MockPackagesMixin {
  String get latestLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  String get testPackageLanguageVersion => latestLanguageVersion;

  /// The path to the test package being used for testing.
  String get testPackageRootPath;

  String convertPath(String fileName) => resourceProvider.convertPath(fileName);

  String toUriStr(String filePath) =>
      pathContext.toUri(convertPath(filePath)).toString();

  /// Writes a package_config.json for the package at [projectFolderPath]. If
  /// [packageName] is not supplied, the last segment of [projectFolderPath] is
  /// used.
  void writePackageConfig(
    String projectFolderPath, {
    // The name of this package. If not provided, the last segment of the path
    // will be used.
    String? packageName,
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool flutter = false,
    bool meta = false,
    bool pedantic = false,
    bool vector_math = false,
    bool macro = false,
  }) {
    projectFolderPath = convertPath(projectFolderPath);

    if (config == null) {
      config = PackageConfigFileBuilder();
    } else {
      config = config.copy();
    }

    // Add this package to its own config.
    config.add(
      name: packageName ?? pathContext.basename(projectFolderPath),
      rootPath: projectFolderPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (meta || flutter) {
      var libFolder = addMeta();
      config.add(name: 'meta', rootPath: libFolder.parent.path);
    }

    if (flutter) {
      {
        var libFolder = addUI();
        config.add(name: 'ui', rootPath: libFolder.parent.path);
      }
      {
        var libFolder = addFlutter();
        config.add(name: 'flutter', rootPath: libFolder.parent.path);
      }
    }

    if (pedantic) {
      var libFolder = addPedantic();
      config.add(name: 'pedantic', rootPath: libFolder.parent.path);
    }

    if (vector_math) {
      var libFolder = addVectorMath();
      config.add(name: 'vector_math', rootPath: libFolder.parent.path);
    }

    if (macro) {
      // TODO(dantup): This code may need to change/be removed depending on how
      //  we ultimately reference the macro packages/libraries.
      final physical = PhysicalResourceProvider.INSTANCE;
      final packageRoot =
          physical.pathContext.normalize(package_root.packageRoot);

      // Copy _fe_analyzer_shared from local SDK into the resource provider.
      final testSharedFolder = resourceProvider
          .getFolder(convertPath('$packagesRootPath/_fe_analyzer_shared'));
      physical
          .getFolder(packageRoot)
          .getChildAssumingFolder('_fe_analyzer_shared/lib/src/macros')
          .copyTo(testSharedFolder.getChildAssumingFolder('lib/src'));
      config.add(name: '_fe_analyzer_shared', rootPath: testSharedFolder.path);

      // Copy dart_internal from local SDK into the memory FS.
      final testInternalFolder = resourceProvider
          .getFolder(convertPath('$packagesRootPath/dart_internal'));
      physical
          .getFolder(packageRoot)
          .getChildAssumingFolder('dart_internal')
          .copyTo(testInternalFolder);
      config.add(name: 'dart_internal', rootPath: testInternalFolder.path);
    }

    _newPackageConfigJsonFile(
      projectFolderPath,
      config.toContent(toUriStr: toUriStr),
    );
  }

  /// Writes a package_config.json for the package under test (considered
  /// 'package:test') that lives in [testPackageRootPath].
  void writeTestPackageConfig({
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool flutter = false,
    bool meta = false,
    bool pedantic = false,
    bool vector_math = false,
    bool macro = false,
  }) {
    writePackageConfig(
      testPackageRootPath,
      config: config,
      languageVersion: languageVersion,
      packageName: 'test',
      flutter: flutter,
      meta: meta,
      pedantic: pedantic,
      vector_math: vector_math,
      macro: macro,
    );
  }

  File _newPackageConfigJsonFile(String packageRootPath, String content) {
    var dartToolDirectoryPath = pathContext.join(
      packageRootPath,
      file_paths.dotDartTool,
    );
    var filePath = pathContext.join(
      dartToolDirectoryPath,
      file_paths.packageConfigJson,
    );
    resourceProvider.getFolder(dartToolDirectoryPath).create();
    return resourceProvider.getFile(filePath)..writeAsStringSync(content);
  }
}
