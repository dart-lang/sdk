// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that global analysis in dart2js propagates positive integers.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

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
  asyncTest(() async {
    var result = await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    var compiler = result.compiler;
    var element = compiler.frontendStrategy.elementEnvironment.mainFunction;
    var code = compiler.backend.getGeneratedCode(element);
    Expect.isFalse(code.contains('ioore'));
  });
}
