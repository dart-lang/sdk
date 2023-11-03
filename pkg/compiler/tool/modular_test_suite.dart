// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test the compilation pipeline of dart2js.
///
/// This is a shell that runs multiple tests, one per folder under `data/`.
import 'dart:async';

import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/runner.dart';
import 'modular_test_suite_helper.dart';

main(List<String> args) async {
  var options = Options.parse(args);
  await resolveScripts(options);
  await Future.wait([
    runSuite(
        sdkRoot.resolve('tests/modular/'),
        'tests/modular',
        options,
        IOPipeline([
          OutlineDillCompilationStep(),
          FullDillCompilationStep(),
          ConcatenateDillsStep(),
          ComputeClosedWorldStep(),
          GlobalAnalysisStep(),
          Dart2jsCodegenStep(codeId0),
          Dart2jsCodegenStep(codeId1),
          Dart2jsEmissionStep(),
          Dart2jsDumpInfoStep(),
          RunD8(),
        ], cacheSharedModules: true)),
  ]);
}
