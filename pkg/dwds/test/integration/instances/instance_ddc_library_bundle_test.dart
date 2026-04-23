// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['daily'])
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import '../fixtures/context.dart';
import 'common/instance_common.dart';

void main() {
  // Enable verbose logging for debugging.
  const debug = false;
  final canaryFeatures = true;
  final moduleFormat = ModuleFormat.ddc;

  group('canary: true | Frontend Server |', () {
    final compilationMode = CompilationMode.frontendServer;
    final provider = TestSdkConfigurationProvider(
      canaryFeatures: canaryFeatures,
      verbose: debug,
      ddcModuleFormat: moduleFormat,
    );
    tearDownAll(provider.dispose);

    runTests(
      provider: provider,
      compilationMode: compilationMode,
      canaryFeatures: canaryFeatures,
    );
  });

  group('canary: true | Build Daemon |', () {
    final compilationMode = CompilationMode.buildDaemon;
    final provider = TestSdkConfigurationProvider(
      canaryFeatures: canaryFeatures,
      verbose: debug,
      ddcModuleFormat: moduleFormat,
    );
    tearDownAll(provider.dispose);

    runTests(
      provider: provider,
      compilationMode: compilationMode,
      canaryFeatures: canaryFeatures,
    );
  });
}
