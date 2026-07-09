// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['daily'])
@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import 'evaluate_common.dart';
import 'fixtures/context.dart';
import 'fixtures/project.dart';

void main() async {
  // Enable verbose logging for debugging.
  const debug = false;

  final provider = TestSdkConfigurationProvider(
    verbose: debug,
    ddcModuleFormat: ModuleFormat.amd,
  );
  tearDownAll(provider.dispose);

  group('Build Daemon |', () {
    testAll(provider: provider, compilationMode: CompilationMode.buildDaemon);
  });

  group('Frontend Server |', () {
    for (final useDebuggerModuleNames in [false, true]) {
      group('Debugger module names: $useDebuggerModuleNames |', () {
        for (final indexBaseMode in IndexBaseMode.values) {
          group(
            'with ${indexBaseMode.name} |',
            () {
              testAll(
                provider: provider,
                compilationMode: CompilationMode.frontendServer,
                indexBaseMode: indexBaseMode,
                useDebuggerModuleNames: useDebuggerModuleNames,
              );
            },
            // https://github.com/dart-lang/sdk/issues/49277
            skip: indexBaseMode == IndexBaseMode.base && Platform.isWindows,
          );
        }
      });
    }
  });
}
