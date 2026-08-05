// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['daily'])
@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import '../fixtures/context.dart';
import 'common/class_inspection_common.dart';

void main() {
  // Enable verbose logging for debugging.
  const debug = false;

  group('canary: true | Frontend Server |', () {
    final canaryFeatures = true;
    final compilationMode = CompilationMode.frontendServer;
    final provider = TestSdkConfigurationProvider(
      verbose: debug,
      canaryFeatures: canaryFeatures,
      ddcModuleFormat: ModuleFormat.ddc,
    );
    tearDownAll(provider.dispose);

    runTests(
      provider: provider,
      compilationMode: compilationMode,
      canaryFeatures: canaryFeatures,
    );
  });

  group('canary: true | Build Daemon |', () {
    final canaryFeatures = true;
    final compilationMode = CompilationMode.buildDaemon;
    final provider = TestSdkConfigurationProvider(
      verbose: debug,
      canaryFeatures: canaryFeatures,
      ddcModuleFormat: ModuleFormat.ddc,
    );
    tearDownAll(provider.dispose);

    runTests(
      provider: provider,
      compilationMode: compilationMode,
      canaryFeatures: canaryFeatures,
    );
  });
}
