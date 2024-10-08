// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

void main() async {
  // Test pkg/test_runner/lib/src/configuration.dart
  test('test environment', () async {
    printOnFailure(Platform.environment.toString());

    final ar = Platform.environment['DART_HOOK_TESTING_C_COMPILER__AR'];
    final cc = Platform.environment['DART_HOOK_TESTING_C_COMPILER__CC'];
    final ld = Platform.environment['DART_HOOK_TESTING_C_COMPILER__LD'];
    final envScript =
        Platform.environment['DART_HOOK_TESTING_C_COMPILER__ENV_SCRIPT'];
    final envScriptArgs = Platform
        .environment['DART_HOOK_TESTING_C_COMPILER__ENV_SCRIPT_ARGUMENTS']
        ?.split(' ');

    if (Platform.isLinux || Platform.isWindows) {
      expect(ar, isNotNull);
      expect(await File(ar!).exists(), true);
      expect(cc, isNotNull);
      expect(await File(cc!).exists(), true);
      expect(ld, isNotNull);
      expect(await File(ld!).exists(), true);
    }
    if (Platform.isWindows) {
      expect(envScript, isNotNull);
      expect(await File(envScript!).exists(), true);
      expect(envScriptArgs, isNotNull);
      expect(envScriptArgs!, isNotEmpty);
    }
  });
}
