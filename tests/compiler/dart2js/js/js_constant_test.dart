// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';
import '../compiler_helper.dart';
import '../memory_compiler.dart';

const String TEST_1 = r"""
  import 'dart:_foreign_helper';
  main() {
    JS('', '#.toString()', -5);
    // absent: "5.toString"
    // present: "(-5).toString"
  }
""";

main() {
  runTest({bool useKernel}) async {
    check(String test) async {
      // Pretend this is a dart2js_native test to allow use of 'native' keyword
      // and import of private libraries.
      String main = 'sdk/tests/compiler/dart2js_native/main.dart';
      Uri entryPoint = Uri.parse('memory:$main');
      var result = await runCompiler(
          entryPoint: entryPoint,
          memorySourceFiles: {main: test},
          options: useKernel ? [] : [Flags.useOldFrontend]);
      Expect.isTrue(result.isSuccess);
      var compiler = result.compiler;
      var closedWorld = compiler.backendClosedWorldForTesting;
      var elementEnvironment = closedWorld.elementEnvironment;

      MemberEntity element = elementEnvironment.mainFunction;
      var backend = compiler.backend;
      String generated = backend.getGeneratedCode(element);
      checkerForAbsentPresent(test)(generated);
    }

    await check(TEST_1);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
