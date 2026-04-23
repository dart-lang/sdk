// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dwds/expression_compiler.dart';
import 'package:dwds/sdk_configuration.dart';
import 'package:logging/logging.dart';

import 'sdk_asset_generator.dart';
import 'test_sdk_layout.dart';

/// Implementation for SDK configuration for tests that can generate
/// missing assets.
///
///  - Generate SDK js, source map (normally included in flutter SDK
///    or produced by build).
class TestSdkConfigurationProvider extends SdkConfigurationProvider {
  final _logger = Logger('TestSdkConfigurationProvider');

  final bool verbose;
  final bool canaryFeatures;
  final ModuleFormat ddcModuleFormat;
  late final Directory _sdkDirectory;
  SdkConfiguration? _configuration;

  late final TestSdkLayout sdkLayout;

  TestSdkConfigurationProvider({
    this.canaryFeatures = false,
    this.verbose = false,
    this.ddcModuleFormat = ModuleFormat.amd,
  }) {
    _sdkDirectory = Directory.systemTemp.createTempSync('sdk_copy');
    sdkLayout = TestSdkLayout.createDefault(_sdkDirectory.path);
  }

  @override
  Future<SdkConfiguration> get configuration async =>
      _configuration ??= await _create();

  /// Generate missing assets in the default SDK layout.
  ///
  /// Creates a copy of the SDK directory where all the missing assets
  /// are generated. Tests using this configuration run using the copy
  /// sdk layout to make sure the actual SDK is not modified.
  Future<SdkConfiguration> _create() async {
    try {
      await copyDirectory(
        TestSdkLayout.defaultSdkDirectory,
        _sdkDirectory.path,
      );
    } catch (e, s) {
      _logger.severe('Failed to create SDK directory copy', e, s);
      dispose();
      rethrow;
    }

    try {
      final assetGenerator = SdkAssetGenerator(
        sdkLayout: sdkLayout,
        canaryFeatures: canaryFeatures,
        verbose: verbose,
        ddcModuleFormat: ddcModuleFormat,
      );

      await assetGenerator.generateSdkAssets();
      return TestSdkLayout.createConfiguration(sdkLayout);
    } catch (e, s) {
      _logger.severe('Failed generate missing assets', e, s);
      dispose();
      rethrow;
    }
  }

  void dispose({bool retry = true}) {
    try {
      if (_sdkDirectory.existsSync()) {
        _sdkDirectory.deleteSync(recursive: true);
      }
    } catch (e, s) {
      _logger.warning('Failed delete SDK directory copy', e, s);
      if (retry) {
        dispose(retry: false);
      }
    }
  }
}
