// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// End-to-end test of the dart2dart compiler.
library dart_backend.end2end_test;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/implementation/dart2jslib.dart';
import 'package:compiler/implementation/dart_backend/dart_backend.dart';
import 'package:expect/expect.dart';

import '../../../../pkg/analyzer2dart/test/test_helper.dart' hide TestSpec;
import '../../../../pkg/analyzer2dart/test/end2end_data.dart';

import 'test_helper.dart';

main() {
  performTests(TEST_DATA, asyncTester, (TestSpec result) {
    asyncTest(() => compilerFor(result.input).then((Compiler compiler) {
      String expectedOutput = result.output.trim();
      compiler.phase = Compiler.PHASE_COMPILING;
      DartBackend backend = compiler.backend;
      backend.assembleProgram();
      String output = compiler.assembledCode.trim();
      Expect.equals(expectedOutput, output,
          '\nInput:\n${result.input}\n'
          'Expected:\n$expectedOutput\n'
          'Actual:\n$output\n');
    }));
  });
}