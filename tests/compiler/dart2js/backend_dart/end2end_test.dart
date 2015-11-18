// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// End-to-end test of the dart2dart compiler.
library dart_backend.end2end_test;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/dart_backend/dart_backend.dart';
import 'package:expect/expect.dart';

import '../../../../pkg/analyzer2dart/test/test_helper.dart' hide TestSpec;
import '../../../../pkg/analyzer2dart/test/end2end_data.dart';

import 'test_helper.dart';
import '../output_collector.dart';

main(List<String> args) {
  performTests(TEST_DATA, asyncTester, runTest, args);
}

runTest(TestSpec result) {
  OutputCollector outputCollector = new OutputCollector();
  asyncTest(() => compilerFor(result.input, outputProvider: outputCollector)
      .then((Compiler compiler) {
    String expectedOutput = result.output.trim();
    compiler.phase = Compiler.PHASE_COMPILING;
    DartBackend backend = compiler.backend;
    backend.assembleProgram();
    String output = outputCollector.getOutput('', 'dart').trim();
    Expect.equals(expectedOutput, output,
        '\nInput:\n${result.input}\n'
        'Expected:\n$expectedOutput\n'
        'Actual:\n$output\n');
  }));
}