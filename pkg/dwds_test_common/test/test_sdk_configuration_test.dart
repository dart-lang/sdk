// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

void main() {
  const debug = false;

  group('Test SDK configuration provider |', () {
    setUpAll(() {
      setCurrentLogWriter(debug: debug);
    });

    test('Creates and deletes SDK directory copy', () async {
      final provider = TestSdkConfigurationProvider(verbose: debug);
      final sdkDirectory = provider.sdkLayout.sdkDirectory;
      final sdkSummary = provider.sdkLayout.summaryPath;
      try {
        expect(
          sdkDirectory,
          _directoryExists,
          reason: 'SDK directory should be created',
        );
        expect(
          sdkSummary,
          isNot(_fileExists),
          reason: 'SDK summary should not be generated yet.',
        );

        await provider.configuration;
        expect(
          sdkSummary,
          _fileExists,
          reason: 'SDK summary should be generated',
        );
      } finally {
        provider.dispose();
        expect(
          sdkDirectory,
          isNot(_directoryExists),
          reason: 'SDK directory copy should be deleted on dispose',
        );
      }
    });
  });

  group('Test SDK configuration | DDC with DDC modules |', () {
    setCurrentLogWriter(debug: debug);
    final provider = TestSdkConfigurationProvider(
      verbose: debug,
      ddcModuleFormat: ModuleFormat.ddc,
    );
    tearDownAll(provider.dispose);

    test('Can validate configuration with generated assets', () async {
      final sdkConfiguration = await provider.configuration;
      sdkConfiguration.validateSdkDir();
      sdkConfiguration.validate();
    });

    test('SDK layout exists', () async {
      await provider.configuration;
      final sdkLayout = provider.sdkLayout;

      expect(sdkLayout.sdkDirectory, _directoryExists);
      expect(sdkLayout.ddcJsPath, _fileExists);
      expect(sdkLayout.ddcJsMapPath, _fileExists);
      expect(sdkLayout.summaryPath, _fileExists);
      expect(sdkLayout.fullDillPath, _fileExists);

      expect(sdkLayout.ddcModuleLoaderJsPath, _fileExists);
      expect(sdkLayout.stackTraceMapperPath, _fileExists);

      expect(sdkLayout.dartPath, _fileExists);
      expect(sdkLayout.frontendServerSnapshotPath, _fileExists);
      expect(sdkLayout.dartdevcSnapshotPath, _fileExists);
      expect(sdkLayout.kernelWorkerSnapshotPath, _fileExists);
      expect(sdkLayout.devToolsDirectory, _directoryExists);
    });
  });

  group('Test SDK configuration | DDC with AMD modules |', () {
    setCurrentLogWriter(debug: debug);
    final provider = TestSdkConfigurationProvider(verbose: debug);
    tearDownAll(provider.dispose);

    test('Can validate configuration with generated assets', () async {
      final sdkConfiguration = await provider.configuration;
      sdkConfiguration.validateSdkDir();
      sdkConfiguration.validate();
    });

    test('SDK layout exists', () async {
      await provider.configuration;
      final sdkLayout = provider.sdkLayout;

      expect(sdkLayout.sdkDirectory, _directoryExists);
      expect(sdkLayout.amdJsPath, _fileExists);
      expect(sdkLayout.amdJsMapPath, _fileExists);
      expect(sdkLayout.summaryPath, _fileExists);
      expect(sdkLayout.fullDillPath, _fileExists);

      expect(sdkLayout.requireJsPath, _fileExists);
      expect(sdkLayout.stackTraceMapperPath, _fileExists);

      expect(sdkLayout.dartPath, _fileExists);
      expect(sdkLayout.dartAotRuntimePath, _fileExists);
      expect(sdkLayout.frontendServerSnapshotPath, _fileExists);
      expect(sdkLayout.dartdevcSnapshotPath, _fileExists);
      expect(sdkLayout.kernelWorkerSnapshotPath, _fileExists);
      expect(sdkLayout.devToolsDirectory, _directoryExists);
    });
  });
}

Matcher _fileExists = predicate(
  (String path) => File(path).existsSync(),
  'File exists',
);

Matcher _directoryExists = predicate(
  (String path) => Directory(path).existsSync(),
  'Directory exists',
);
