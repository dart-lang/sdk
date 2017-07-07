// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import '../kernel/compile_from_dill_test_helper.dart';
import '../serialization/helper.dart';

main(List<String> args) {
  useJsStrategyForTesting = true;
  asyncTest(() async {
    await mainInternal(args);
  });
}

Future mainInternal(List<String> args,
    {bool skipWarnings: false,
    bool skipErrors: false,
    List<String> options: const <String>[]}) async {
  Arguments arguments = new Arguments.from(args);
  List<Test> tests;
  if (arguments.uri != null) {
    tests = <Test>[new Test.fromUri(arguments.uri)];
  } else {
    tests = TESTS;
  }
  for (Test test in tests) {
    if (test.uri != null) {
      print('--- running test uri ${test.uri} -------------------------------');
    } else {
      print(
          '--- running test code -------------------------------------------');
      print(test.sources.values.first);
      print('----------------------------------------------------------------');
    }
    await runTest(test.entryPoint, test.sources,
        verbose: arguments.verbose,
        skipWarnings: skipWarnings,
        skipErrors: skipErrors,
        options: options,
        expectAstEquivalence: false,
        expectIdenticalOutput: false);
  }
}
