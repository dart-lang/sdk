// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:native_assets_cli/native_assets_cli_internal.dart'
    show CCompilerConfigImpl;
import 'package:test/test.dart';

void main() async {
  // Test pkg/test_runner/lib/src/configuration.dart
  test('test environment', () async {
    printOnFailure(Platform.environment.toString());

    String unparseKey(String key) => key.replaceAll('.', '__').toUpperCase();

    final arKey = unparseKey(CCompilerConfigImpl.arConfigKeyFull);
    final ccKey = unparseKey(CCompilerConfigImpl.ccConfigKeyFull);
    final ldKey = unparseKey(CCompilerConfigImpl.ldConfigKeyFull);
    final envScriptKey = unparseKey(CCompilerConfigImpl.envScriptConfigKeyFull);
    final envScriptArgsKey =
        unparseKey(CCompilerConfigImpl.envScriptArgsConfigKeyFull);

    if (Platform.isLinux || Platform.isWindows) {
      expect(Platform.environment[arKey], isNotEmpty);
      expect(await File(Platform.environment[arKey]!).exists(), true);
      expect(Platform.environment[ccKey], isNotEmpty);
      expect(await File(Platform.environment[ccKey]!).exists(), true);
      expect(Platform.environment[ldKey], isNotEmpty);
      expect(await File(Platform.environment[ldKey]!).exists(), true);
    }
    if (Platform.isWindows) {
      expect(Platform.environment[envScriptKey], isNotEmpty);
      expect(await File(Platform.environment[envScriptKey]!).exists(), true);
      expect(Platform.environment[envScriptArgsKey], isNotEmpty);
    }
  });
}
