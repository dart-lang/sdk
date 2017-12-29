// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';
import '../type_mask_test_helper.dart';

const String TEST = """
bar() => 42;
baz() => bar;

class A {
  foo() => 42;
}

class B extends A {
  foo() => super.foo;
}

main() {
  baz();
  new B().foo();
}
""";

void main() {
  runTest({bool useKernel}) async {
    var result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        options: useKernel ? [Flags.useKernel] : []);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;
    var elementEnvironment = closedWorld.elementEnvironment;
    var commonMasks = closedWorld.commonMasks;

    checkReturn(String name, type) {
      MemberEntity element = elementEnvironment.lookupLibraryMember(
          elementEnvironment.mainLibrary, name);
      Expect.equals(
          type,
          simplify(typesInferrer.getReturnTypeOfMember(element), closedWorld),
          name);
    }

    checkReturnInClass(String className, String methodName, type) {
      dynamic cls = elementEnvironment.lookupClass(
          elementEnvironment.mainLibrary, className);
      var element = elementEnvironment.lookupClassMember(cls, methodName);
      Expect.equals(type,
          simplify(typesInferrer.getReturnTypeOfMember(element), closedWorld));
    }

    checkReturn('bar', commonMasks.uint31Type);
    checkReturn('baz', commonMasks.functionType);

    checkReturnInClass('A', 'foo', commonMasks.uint31Type);
    checkReturnInClass('B', 'foo', commonMasks.functionType);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
