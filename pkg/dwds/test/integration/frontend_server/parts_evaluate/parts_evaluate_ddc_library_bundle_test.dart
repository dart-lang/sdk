// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/fixtures/project.dart';
import 'package:dwds_test_common/integration/evaluate_parts.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import '../../fixtures/frontend_server_context.dart';

void main() async {
  // Enable verbose logging for debugging.
  const debug = false;

  final provider = TestSdkConfigurationProvider(
    verbose: debug,
    ddcModuleFormat: ModuleFormat.ddc,
    canaryFeatures: true,
  );
  tearDownAll(provider.dispose);

  group('Frontend Server | Context with part files | with noBase |', () {
    testAll(
      provider: provider,
      contextFactory: FrontendServerTestContext.new,
      indexBaseMode: IndexBaseMode.noBase,
      useDebuggerModuleNames: true,
    );
  });
}
