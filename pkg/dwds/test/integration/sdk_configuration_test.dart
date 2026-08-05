// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:dwds/src/utilities/sdk_configuration.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

var _throwsDoesNotExistException = throwsA(
  isA<InvalidSdkConfigurationException>().having(
    (e) => '$e',
    'message',
    contains('does not exist'),
  ),
);

void main() {
  group('Basic configuration', () {
    test('Can validate default configuration layout', () async {
      final defaultConfiguration =
          await const DefaultSdkConfigurationProvider().configuration;
      defaultConfiguration.validateSdkDir();
      defaultConfiguration.validateSummaries();
    });

    test('Cannot validate an empty configuration layout', () async {
      final emptyConfiguration = const SdkConfiguration.empty();
      expect(emptyConfiguration.validateSdkDir, _throwsDoesNotExistException);
      expect(emptyConfiguration.validate, _throwsDoesNotExistException);
    });
  });

  group('Non-standard configuration', () {
    late Directory outputDir;

    setUp(() async {
      final systemTempDir = Directory.systemTemp;
      outputDir = systemTempDir.createTempSync('foo bar');
    });

    tearDown(() async {
      await outputDir.delete(recursive: true);
    });

    test('Can validate existing configuration layout', () async {
      final defaultSdkConfiguration =
          await const DefaultSdkConfigurationProvider().configuration;

      final sdkDirectory = outputDir.path;
      final sdkLayout = FakeSdkLayout(sdkDirectory);
      final sdkConfiguration = FakeSdkLayout.createConfiguration(sdkLayout);

      final sdkSummaryPath = sdkLayout.summaryPath;
      final summariesDir = p.dirname(sdkSummaryPath);

      Directory(summariesDir).createSync(recursive: true);
      File(defaultSdkConfiguration.sdkSummaryPath!).copySync(sdkSummaryPath);

      final compilerWorkerPath = sdkLayout.compilerWorkerPath;
      final workerDir = p.dirname(compilerWorkerPath);

      Directory(workerDir).createSync(recursive: true);
      File(
        defaultSdkConfiguration.compilerWorkerPath!,
      ).copySync(compilerWorkerPath);

      expect(sdkConfiguration.sdkDirectory, equals(sdkDirectory));
      expect(sdkConfiguration.sdkSummaryPath, equals(sdkSummaryPath));
      expect(sdkConfiguration.compilerWorkerPath, equals(compilerWorkerPath));

      sdkConfiguration.validateSdkDir();
      sdkConfiguration.validateSummaries();
    });

    test('Cannot validate non-existing configuration layout', () async {
      final sdkDirectory = outputDir.path;

      final sdkLayout = FakeSdkLayout(sdkDirectory);
      final sdkConfiguration = FakeSdkLayout.createConfiguration(sdkLayout);

      sdkConfiguration.validateSdkDir();
      expect(sdkConfiguration.validate, _throwsDoesNotExistException);
    });
  });

  group('SDK configuration with memory file system', () {
    late MemoryFileSystem fs;

    final root = '/root';
    final sdkDirectory = root;

    final sdkLayout = SdkLayout.createDefault(sdkDirectory);
    final sdkConfiguration = SdkConfiguration.fromSdkLayout(sdkLayout);
    final sdkSummaryPath = sdkLayout.summaryPath;
    final compilerWorkerPath = sdkLayout.dartdevcSnapshotPath;

    setUp(() async {
      fs = MemoryFileSystem();
      await fs.directory(sdkDirectory).create(recursive: true);
      await fs.file(sdkSummaryPath).create(recursive: true);
      await fs.file(compilerWorkerPath).create(recursive: true);
    });

    test('Can create and validate default SDK configuration', () async {
      expect(sdkConfiguration.sdkDirectory, equals(sdkDirectory));
      expect(sdkConfiguration.sdkSummaryPath, equals(sdkSummaryPath));
      expect(sdkConfiguration.compilerWorkerPath, equals(compilerWorkerPath));

      sdkConfiguration.validateSdkDir(fileSystem: fs);
      sdkConfiguration.validate(fileSystem: fs);
    });
  });

  group('Test configuration', () {
    final provider = TestSdkConfigurationProvider();
    tearDownAll(provider.dispose);

    test('Can validate configuration layout with generated assets', () async {
      final sdkConfiguration = await provider.configuration;
      sdkConfiguration.validateSdkDir();
      sdkConfiguration.validate();
    });
  });
}

class FakeSdkLayout {
  final String sdkDirectory;

  static SdkConfiguration createConfiguration(FakeSdkLayout sdkLayout) =>
      SdkConfiguration(
        sdkDirectory: sdkLayout.sdkDirectory,
        sdkSummaryPath: sdkLayout.summaryPath,
        compilerWorkerPath: sdkLayout.compilerWorkerPath,
      );

  FakeSdkLayout(this.sdkDirectory);

  String get summaryPath => p.join(sdkDirectory, 'summaries', 'outline.dill');

  String get compilerWorkerPath =>
      p.join(sdkDirectory, 'snapshots', 'test.snapshot');
}
