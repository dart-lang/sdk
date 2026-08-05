// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import 'asset_handler_common.dart';

void main() {
  // Enable verbose logging for debugging.
  const debug = false;
  final canary = true;
  final provider = TestSdkConfigurationProvider(
    verbose: debug,
    canaryFeatures: canary,
    ddcModuleFormat: ModuleFormat.ddc,
  );
  tearDownAll(provider.dispose);

  testAll(provider: provider);
}
