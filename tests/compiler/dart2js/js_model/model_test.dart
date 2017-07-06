// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:expect/expect.dart';
import '../kernel/compile_from_dill_test_helper.dart';
import '../kernel/compiler_helper.dart';
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

    enableDebugMode();

    Compiler compiler1 = await compileWithDill(test.entryPoint, test.sources, [
      Flags.disableInlining,
      Flags.disableTypeInference
    ], beforeRun: (Compiler compiler) {
      compiler.backendStrategy = new JsBackendStrategy(compiler);
    }, printSteps: true);
    Expect.isFalse(compiler1.compilationFailed);
  }
}
