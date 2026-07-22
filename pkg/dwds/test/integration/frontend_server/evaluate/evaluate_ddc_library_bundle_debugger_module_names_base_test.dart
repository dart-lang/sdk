// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/fixtures/project.dart';
import 'package:dwds_test_common/integration/evaluate.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import '../../fixtures/frontend_server_context.dart';

void main() async {
  // Enable verbose logging for debugging.
  const debug = false;

  group('Canary: true |', () {
    final provider = TestSdkConfigurationProvider(
      verbose: debug,
      ddcModuleFormat: ModuleFormat.ddc,
      canaryFeatures: true,
    );
    tearDownAll(provider.dispose);

    group('Frontend Server | Debugger module names: true | with base |', () {
      testAll(
        provider: provider,
        contextFactory: FrontendServerTestContext.new,
        indexBaseMode: IndexBaseMode.base,
        useDebuggerModuleNames: true,
      );
    }, skip: Platform.isWindows ? 'Skipped on Windows' : null);
  });
}
