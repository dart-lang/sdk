// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''
main (x, y) {
  if (x != null) {
    if (y != null) {
      // Forces x and y to be int-checked.
      int a = x;
      int b = y;
      // Now we must be able to do a direct "+" operation in JS.
      return x + y;
    }
  }
}
''',
};

main() {
  runTest() async {
    var options = [Flags.enableCheckedMode];
    var result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, options: options);
    var compiler = result.compiler;
    var element =
        compiler.backendClosedWorldForTesting.elementEnvironment.mainFunction;
    var code = compiler.backendStrategy.getGeneratedCodeForTesting(element);
    Expect.isTrue(code.contains('+'), code);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
