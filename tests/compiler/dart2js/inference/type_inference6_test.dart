// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';
import 'type_mask_test_helper.dart';
import '../memory_compiler.dart';

const String TEST = r"""
foo() {
  var a = [1, 2, 3];
  return a.first;
}

main() {
  foo();
}
""";

main() {
  runTest({bool useKernel}) async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        options: useKernel ? [Flags.useKernel] : []);
    Expect.isTrue(result.isSuccess);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;
    var commonMasks = closedWorld.commonMasks;
    MemberEntity element = findMember(closedWorld, "foo");
    var mask = typesInferrer.getReturnTypeOfMember(element);
    Expect.equals(commonMasks.uint31Type, simplify(mask, closedWorld));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
