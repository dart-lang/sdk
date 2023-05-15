// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main(List<String> args) async {
  if (Platform.isMacOS) {
    // We don't set any compiler paths on MacOS in
    // pkg/test_runner/lib/src/configuration.dart
    // nativeCompilerEnvironmentVariables.
    return;
  }

  test('run in isolation', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      String unparseKey(String key) => key.replaceAll('.', '__').toUpperCase();
      final arKey = unparseKey(CCompilerConfig.arConfigKeyFull);
      final ccKey = unparseKey(CCompilerConfig.ccConfigKeyFull);
      final ldKey = unparseKey(CCompilerConfig.ldConfigKeyFull);
      final envScriptKey = unparseKey(CCompilerConfig.envScriptConfigKeyFull);
      final envScriptArgsKey =
          unparseKey(CCompilerConfig.envScriptArgsConfigKeyFull);

      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      await runPubGet(workingDirectory: packageUri, logger: logger);

      final cc = Platform.environment[ccKey]?.fileUri;
      printOnFailure(
          'Platform.environment[ccKey]: ${Platform.environment[ccKey]}');
      printOnFailure('cc: $cc');

      final assets = await build(
        packageUri,
        logger,
        dartExecutable,
        // Manually pass in a compiler.
        cCompilerConfig: CCompilerConfig(
          ar: Platform.environment[arKey]?.fileUri,
          cc: cc,
          envScript: Platform.environment[envScriptKey]?.fileUri,
          envScriptArgs: Platform.environment[envScriptArgsKey]?.split(' '),
          ld: Platform.environment[ldKey]?.fileUri,
        ),
        // Prevent any other environment variables.
        includeParentEnvironment: false,
      );
      expect(assets.length, 1);
    });
  });
}

extension on String {
  Uri get fileUri => Uri.file(this);
}
