// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/commandline_options.dart';
import '../memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

foo(int x, int y) {
  return x + y;
}

main (x, y) {
  if (x != null) {
    if (y != null) {
      return foo(x, y);
    }
  }
}
''',
};

main() {
  runTest() async {
    var options = [Flags.trustTypeAnnotations];
    var result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, options: options);
    var compiler = result.compiler;
    var element =
        compiler.backendClosedWorldForTesting.elementEnvironment.mainFunction;
    var code = compiler.backend.getGeneratedCode(element);
    Expect.isTrue(code.contains('+'), code);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
