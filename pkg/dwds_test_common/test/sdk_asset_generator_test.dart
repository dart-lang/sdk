// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/sdk_asset_generator.dart';
import 'package:dwds_test_common/test_sdk_layout.dart';
import 'package:test/test.dart';

void main() {
  group('SDK asset generator', () {
    const debug = false;

    late Directory tempDir;
    late String sdkDirectory;
    late String compilerWorkerPath;

    // Missing assets
    late String amdSdkJsPath;
    late String amdSdkJsMapPath;
    late String ddcSdkJsPath;
    late String ddcSdkJsMapPath;

    setUp(() async {
      setCurrentLogWriter(debug: debug);
      tempDir = Directory.systemTemp.createTempSync();

      sdkDirectory = tempDir.path;
      final copySdkLayout = TestSdkLayout.createDefault(sdkDirectory);

      compilerWorkerPath = copySdkLayout.dartdevcSnapshotPath;

      // Copy the SDK directory into a temp directory.
      await copyDirectory(TestSdkLayout.defaultSdkDirectory, sdkDirectory);

      // Simulate missing assets.
      amdSdkJsPath = copySdkLayout.amdJsPath;
      amdSdkJsMapPath = copySdkLayout.amdJsMapPath;
      ddcSdkJsPath = copySdkLayout.ddcJsPath;
      ddcSdkJsMapPath = copySdkLayout.ddcJsMapPath;

      _deleteIfExists(amdSdkJsPath);
      _deleteIfExists(amdSdkJsMapPath);
      _deleteIfExists(ddcSdkJsPath);
      _deleteIfExists(ddcSdkJsMapPath);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'Can generate missing SDK assets and validate SDK configuration for the '
      'AMD module system',
      () async {
        final sdkLayout = TestSdkLayout.createDefault(sdkDirectory);
        final configuration = TestSdkLayout.createConfiguration(sdkLayout);

        final assetGenerator = SdkAssetGenerator(
          sdkLayout: sdkLayout,
          verbose: true,
          canaryFeatures: false,
          ddcModuleFormat: ModuleFormat.amd,
        );
        await assetGenerator.generateSdkAssets();

        // Make sure SDK configuration and asset generator agree on the file
        // paths.
        expect(configuration.sdkDirectory, equals(sdkDirectory));
        expect(configuration.compilerWorkerPath, equals(compilerWorkerPath));

        expect(sdkLayout.amdJsPath, equals(amdSdkJsPath));
        expect(sdkLayout.amdJsMapPath, equals(amdSdkJsMapPath));

        // Validate that configuration files exist.
        configuration.validateSdkDir();
        configuration.validate();

        // Validate all assets exist.
        expect(sdkLayout.amdJsPath, _exists);
        expect(sdkLayout.amdJsMapPath, _exists);
      },
    );

    test(
      'Can generate missing SDK assets and validate SDK configuration for the '
      'DDC module system',
      () async {
        final sdkLayout = TestSdkLayout.createDefault(sdkDirectory);
        final configuration = TestSdkLayout.createConfiguration(sdkLayout);

        final assetGenerator = SdkAssetGenerator(
          sdkLayout: sdkLayout,
          verbose: true,
          canaryFeatures: false,
          ddcModuleFormat: ModuleFormat.ddc,
        );
        await assetGenerator.generateSdkAssets();

        // Make sure SDK configuration and asset generator agree on the file
        // paths.
        expect(configuration.sdkDirectory, equals(sdkDirectory));
        expect(configuration.compilerWorkerPath, equals(compilerWorkerPath));

        expect(sdkLayout.ddcJsPath, equals(ddcSdkJsPath));
        expect(sdkLayout.ddcJsMapPath, equals(ddcSdkJsMapPath));

        // Validate that configuration files exist.
        configuration.validateSdkDir();
        configuration.validate();

        // Validate all assets exist.
        expect(sdkLayout.ddcJsPath, _exists);
        expect(sdkLayout.ddcJsMapPath, _exists);
      },
    );

    test(
      'Can generate missing SDK assets with canary features enabled',
      () async {
        final sdkLayout = TestSdkLayout.createDefault(sdkDirectory);

        final assetGenerator = SdkAssetGenerator(
          sdkLayout: sdkLayout,
          verbose: true,
          canaryFeatures: true,
          ddcModuleFormat: ModuleFormat.amd,
        );
        await assetGenerator.generateSdkAssets();

        final sdk = File(amdSdkJsPath).readAsStringSync();
        expect(sdk, contains('canary'));
      },
    );

    test('Can generate missing SDK assets with canary features enabled for the '
        'DDC module system', () async {
      final sdkLayout = TestSdkLayout.createDefault(sdkDirectory);

      final assetGenerator = SdkAssetGenerator(
        sdkLayout: sdkLayout,
        verbose: true,
        canaryFeatures: true,
        ddcModuleFormat: ModuleFormat.ddc,
      );
      await assetGenerator.generateSdkAssets();

      final sdk = File(ddcSdkJsPath).readAsStringSync();
      expect(sdk, contains('canary'));
    });
  });
}

Matcher _exists = predicate(
  (String path) => File(path).existsSync(),
  'File exists',
);

void _deleteIfExists(String path) {
  final file = File(path);
  if (file.existsSync()) {
    file.deleteSync();
  }
}
