// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to have a bogus
// implementation of var.== and
// var.hashCode.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

import 'dart:typed_data';

a() => [0];
b() => [1, 2];
c() => new Uint8List(1);
d() => new Uint8List(2);

main() {
  print(a); print(b); print(c); print(d);
}
''',
};

main() {
  asyncTest(() async {
    var result = await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;

    var element =
        compiler.frontendStrategy.elementEnvironment.mainLibrary.find('a');
    var mask1 = typesInferrer.getReturnTypeOfElement(element);

    element =
        compiler.frontendStrategy.elementEnvironment.mainLibrary.find('b');
    var mask2 = typesInferrer.getReturnTypeOfElement(element);

    element =
        compiler.frontendStrategy.elementEnvironment.mainLibrary.find('c');
    var mask3 = typesInferrer.getReturnTypeOfElement(element);

    element =
        compiler.frontendStrategy.elementEnvironment.mainLibrary.find('d');
    var mask4 = typesInferrer.getReturnTypeOfElement(element);

    Expect.notEquals(
        mask1.union(mask2, closedWorld), mask3.union(mask4, closedWorld));
  });
}
