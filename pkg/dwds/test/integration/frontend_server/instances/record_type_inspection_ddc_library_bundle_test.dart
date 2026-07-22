// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/integration/record_type_inspection.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import '../../fixtures/frontend_server_context.dart';

void main() {
  // Enable verbose logging for debugging.
  const debug = false;
  final canaryFeatures = true;

  group('canary: true | Frontend Server |', () {
    final contextFactory = FrontendServerTestContext.new;
    final provider = TestSdkConfigurationProvider(
      verbose: debug,
      canaryFeatures: canaryFeatures,
      ddcModuleFormat: ModuleFormat.ddc,
    );
    tearDownAll(provider.dispose);
    runTests(
      provider: provider,
      contextFactory: contextFactory,
      canaryFeatures: canaryFeatures,
    );
  });
}
