// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that global analysis in dart2js propagates positive integers.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

var a = [42];

main() {
  var value = a[0];
  if (value < 42) {
    return new List(42)[value];
  }
}
''',
};

main() {
  runTest({bool useKernel}) async {
    var result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES,
        options: useKernel ? [] : [Flags.useOldFrontend]);
    var compiler = result.compiler;
    var element =
        compiler.backendClosedWorldForTesting.elementEnvironment.mainFunction;
    var code = compiler.backend.getGeneratedCode(element);
    Expect.isFalse(code.contains('ioore'));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
