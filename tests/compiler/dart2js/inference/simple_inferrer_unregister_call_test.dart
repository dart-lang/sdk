// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import 'type_mask_test_helper.dart';
import '../memory_compiler.dart';

const String TEST = """
var a = '';
class A {
  operator+(other) => other;
}

foo() {
  // The following '+' call will first say that it may call A::+,
  // String::+, or int::+. After all methods have been analyzed, we know
  // that a is of type String, and therefore, this method cannot call
  // A::+. Therefore, the type of the parameter of A::+ will be the
  // one given by the other calls.
  return a + 'foo';
}

main() {
  new A() + 42;
  foo();
}
""";

void main() {
  runTest({bool useKernel}) async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        options: useKernel ? [Flags.useKernel] : []);
    Expect.isTrue(result.isSuccess);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;

    checkReturnInClass(String className, String methodName, type) {
      var element = findClassMember(closedWorld, className, methodName);
      Expect.equals(type, typesInferrer.getReturnTypeOfMember(element));
    }

    checkReturnInClass(
        'A', '+', typesInferrer.closedWorld.commonMasks.uint31Type);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
