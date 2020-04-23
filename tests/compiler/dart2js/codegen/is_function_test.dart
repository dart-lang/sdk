// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Test that checks that we are not added $isFunction properties on closure
/// classes.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

const String SOURCE = '''
import 'dart:isolate';
main(arg) {}
''';

main() {
  runTest() async {
    List<String> options = [Flags.enableCheckedMode];
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': SOURCE}, options: options);
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    Program program =
        compiler.backendStrategy.emitterTask.emitter.programForTesting;
    JsBackendStrategy backendStrategy = compiler.backendStrategy;
    var name = backendStrategy.namerForTesting.operatorIs(
        compiler.backendClosedWorldForTesting.commonElements.functionClass);
    for (Fragment fragment in program.fragments) {
      for (Library library in fragment.libraries) {
        for (Class cls in library.classes) {
          if (!cls.element.isClosure) continue;
          for (StubMethod stub in cls.isChecks) {
            Expect.notEquals(
                stub.name.key, name.key, "Unexpected ${name.key} stub on $cls");
          }
        }
      }
    }
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
