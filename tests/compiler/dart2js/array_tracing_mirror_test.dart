// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure that limiting mirrors through @MirrorsUsed does not
// affect optimizations done on arrays.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

@MirrorsUsed(targets: 'main')
import 'dart:mirrors';
class A {
  var field;
}

main() {
  var a = new A();
  var mirror = reflect(a);
  var array = [42, 42];
  a.field = array;
  var field = mirror.getField(#field);
  field.invoke(#clear, []);
  return array.length;
}
''',
};

main() {
  asyncTest(() async {
    var result = await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    var compiler = result.compiler;
    var element = compiler.frontendStrategy.elementEnvironment.mainFunction;
    var code = compiler.backend.getGeneratedCode(element);
    Expect.isTrue(code.contains('return 2'), "Unexpected code:\n$code");
  });
}
