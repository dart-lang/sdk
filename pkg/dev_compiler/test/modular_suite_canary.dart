// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test the modular compilation pipeline of ddc in canary mode.
///
/// This is a shell that runs multiple tests, one per folder under `data/`.
library;

import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/runner.dart';
import 'package:modular_test/src/steps/macro_precompile_aot.dart';

import 'modular_helpers.dart';

void main(List<String> args) async {
  final options = Options.parse(args);
  final soundNullSafety = true;
  await resolveScripts(options);
  await runSuite(
      sdkRoot.resolve('tests/modular/'),
      'tests/modular',
      options,
      IOPipeline([
        PrecompileMacroAotStep(verbose: options.verbose),
        SourceToSummaryDillStep(soundNullSafety: soundNullSafety),
        DDCStep(soundNullSafety: soundNullSafety, canaryFeatures: true),
        RunD8(),
      ], cacheSharedModules: true));
}
