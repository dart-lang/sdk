// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';

/// A mixin adding functionality to write `.dart_tool/package_config.json`
/// files along with mock packages to a [ResourceProvider].
mixin ConfigurationFilesMixin on MockPackagesMixin {
  /// The Dart language version of the test package being used for testing.
  String get testPackageLanguageVersion => _latestLanguageVersion;

  /// The path to the test package being used for testing.
  String get testPackageRootPath;

  String get _latestLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

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
    bool flutter_test = false,
    bool meta = false,
    bool pedantic = false,
    bool vector_math = false,
  }) {
    projectFolderPath = resourceProvider.convertPath(projectFolderPath);

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
      var uiLibFolder = addUI();
      config.add(name: 'ui', rootPath: uiLibFolder.parent.path);

      var flutterLibFolder = addFlutter();
      config.add(name: 'flutter', rootPath: flutterLibFolder.parent.path);
    }

    if (flutter_test) {
      var libFolder = addFlutterTest();
      config.add(name: 'flutter_test', rootPath: libFolder.parent.path);
    }

    if (pedantic) {
      var libFolder = addPedantic();
      config.add(name: 'pedantic', rootPath: libFolder.parent.path);
    }

    if (vector_math) {
      var libFolder = addVectorMath();
      config.add(name: 'vector_math', rootPath: libFolder.parent.path);
    }

    var content = config.toContent(
      toUriStr:
          (p) => pathContext.toUri(resourceProvider.convertPath(p)).toString(),
    );

    var projectFolder = resourceProvider.getFolder(projectFolderPath);
    var dartToolFolder = projectFolder.getChildAssumingFolder(
      file_paths.dotDartTool,
    )..create();
    dartToolFolder
        .getChildAssumingFile(file_paths.packageConfigJson)
        .writeAsStringSync(content);
  }

  /// Writes a package_config.json for the package under test (considered
  /// 'package:test') that lives in [testPackageRootPath].
  void writeTestPackageConfig({
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool flutter = false,
    bool flutter_test = false,
    bool meta = false,
    bool pedantic = false,
    bool vector_math = false,
  }) {
    writePackageConfig(
      testPackageRootPath,
      config: config,
      languageVersion: languageVersion,
      packageName: 'test',
      flutter: flutter,
      flutter_test: flutter_test,
      meta: meta,
      pedantic: pedantic,
      vector_math: vector_math,
    );
  }
}
