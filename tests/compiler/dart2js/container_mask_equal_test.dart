// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to have a bogus
// implementation of var.== and
// var.hashCode.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
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
  runTests({bool useKernel}) async {
    var result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES,
        options: useKernel ? [Flags.useKernel] : []);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;
    var elementEnvironment = closedWorld.elementEnvironment;

    var element = elementEnvironment.lookupLibraryMember(
        elementEnvironment.mainLibrary, 'a');
    var mask1 = typesInferrer.getReturnTypeOfMember(element);

    element = elementEnvironment.lookupLibraryMember(
        elementEnvironment.mainLibrary, 'b');
    var mask2 = typesInferrer.getReturnTypeOfMember(element);

    element = elementEnvironment.lookupLibraryMember(
        elementEnvironment.mainLibrary, 'c');
    var mask3 = typesInferrer.getReturnTypeOfMember(element);

    element = elementEnvironment.lookupLibraryMember(
        elementEnvironment.mainLibrary, 'd');
    var mask4 = typesInferrer.getReturnTypeOfMember(element);

    Expect.notEquals(
        mask1.union(mask2, closedWorld), mask3.union(mask4, closedWorld));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}
