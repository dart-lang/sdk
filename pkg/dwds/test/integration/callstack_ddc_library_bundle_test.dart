// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import 'callstack_common.dart';
import 'fixtures/context.dart';

void main() {
  // Enable verbose logging for debugging.
  const debug = false;

  final provider = TestSdkConfigurationProvider(
    verbose: debug,
    ddcModuleFormat: ModuleFormat.ddc,
    canaryFeatures: true,
  );
  tearDownAll(provider.dispose);

  group('Build Daemon |', () {
    testCallStack(
      provider: provider,
      compilationMode: CompilationMode.buildDaemon,
    );
  });

  group('Frontend Server |', () {
    testCallStack(
      provider: provider,
      compilationMode: CompilationMode.frontendServer,
    );
  });
}
