// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;

import '../src/utilities/mock_packages.dart';

mixin ConfigurationFilesMixin on ResourceProviderMixin {
  String get latestLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  String get testPackageLanguageVersion => latestLanguageVersion;

  void writePackageConfig(
    String projectFolderPath, {
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool flutter = false,
    bool meta = false,
    bool pedantic = false,
    bool vector_math = false,
    // TODO(dantup): Remove this flag when we no longer need to copy packages
    //  for macro support.
    bool temporaryMacroSupport = false,
  }) {
    if (config == null) {
      config = PackageConfigFileBuilder();
    } else {
      config = config.copy();
    }

    config.add(
      name: 'test',
      rootPath: projectFolderPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (meta || flutter) {
      var libFolder = MockPackages.instance.addMeta(resourceProvider);
      config.add(name: 'meta', rootPath: libFolder.parent.path);
    }

    if (flutter) {
      {
        var libFolder = MockPackages.instance.addUI(resourceProvider);
        config.add(name: 'ui', rootPath: libFolder.parent.path);
      }
      {
        var libFolder = MockPackages.instance.addFlutter(resourceProvider);
        config.add(name: 'flutter', rootPath: libFolder.parent.path);
      }
    }

    if (pedantic) {
      var libFolder = MockPackages.instance.addPedantic(resourceProvider);
      config.add(name: 'pedantic', rootPath: libFolder.parent.path);
    }

    if (vector_math) {
      var libFolder = MockPackages.instance.addVectorMath(resourceProvider);
      config.add(name: 'vector_math', rootPath: libFolder.parent.path);
    }

    if (temporaryMacroSupport) {
      final testPackagesRootPath = resourceProvider.convertPath('/packages');

      final physical = PhysicalResourceProvider.INSTANCE;
      final packageRoot =
          physical.pathContext.normalize(package_root.packageRoot);

      // Copy _fe_analyzer_shared from local SDK into the memory FS.
      final testSharedFolder =
          getFolder('$testPackagesRootPath/_fe_analyzer_shared');
      physical
          .getFolder(packageRoot)
          .getChildAssumingFolder('_fe_analyzer_shared/lib/src/macros')
          .copyTo(testSharedFolder.getChildAssumingFolder('lib/src'));
      config.add(name: '_fe_analyzer_shared', rootPath: testSharedFolder.path);

      // Copy dart_internal from local SDK into the memory FS.
      final testInternalFolder =
          getFolder('$testPackagesRootPath/dart_internal');
      physical
          .getFolder(packageRoot)
          .getChildAssumingFolder('dart_internal')
          .copyTo(testInternalFolder);
      config.add(name: 'dart_internal', rootPath: testInternalFolder.path);
    }

    newPackageConfigJsonFile(
        projectFolderPath, config.toContent(toUriStr: toUriStr));
  }
}
