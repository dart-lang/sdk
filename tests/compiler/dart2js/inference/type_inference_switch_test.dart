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

const String TEST1 = r"""
foo(int x) {
  var a = "one";
  switch (x) {
    case 1:
      a = "two";
      break;
    case 2:
      break;
  }

  return a;
}

main() {
  foo(new DateTime.now().millisecondsSinceEpoch);
}
""";

const String TEST2 = r"""
foo(int x) {
  var a;
  switch (x) {
    case 1:
      a = "two";
      break;
    case 2:
      break;
  }

  return a;
}

main() {
  foo(new DateTime.now().millisecondsSinceEpoch);
}
""";

const String TEST3 = r"""
foo(int x) {
  var a;
  switch (x) {
    case 1:
      a = 1;
    case 2:  // illegal fall through
      a = 2;
      break;
  }

  return a;
}

main() {
  foo(new DateTime.now().millisecondsSinceEpoch);
}
""";

const String TEST4 = r"""
foo(int x) {
  var a;
  switch (x) {
    case 1:
      a = 1;
    case 2:  // illegal fall through
      a = 2;
      break;
    default:
      a = 0;
  }

  return a;
}

main() {
  foo(new DateTime.now().millisecondsSinceEpoch);
}
""";

const String TEST5 = r"""
foo(int x) {
  var a;
  switch (x) {
    case 1:
      a = 1;
      break;
    case 2:
      a = 2;
      break;
    default:
  }

  return a;
}

main() {
  foo(new DateTime.now().millisecondsSinceEpoch);
}
""";

const String TEST6 = r"""
foo(int x) {
  var a;
  do {  // add extra locals scope
    switch (x) {
      case 1:
        a = 1;
        break;
      case 2:
        a = 2;
        break;
    }
  } while (false);

  return a;
}

main() {
  foo(new DateTime.now().millisecondsSinceEpoch);
}
""";

main() {
  runTests({bool useKernel}) async {
    runTest(String test, checker) async {
      CompilationResult result = await runCompiler(
          memorySourceFiles: {'main.dart': test},
          options: useKernel ? [Flags.useKernel] : []);
      Expect.isTrue(result.isSuccess);
      var compiler = result.compiler;
      var typesInferrer = compiler.globalInference.typesInferrerInternal;
      var closedWorld = typesInferrer.closedWorld;
      var commonMasks = closedWorld.commonMasks;

      checkTypeOf(String name, TypeMask type) {
        FunctionEntity element = findMember(closedWorld, name);
        var mask = typesInferrer.getReturnTypeOfMember(element);
        Expect.equals(type, simplify(mask, closedWorld));
      }

      checker(commonMasks, checkTypeOf);
    }

    await runTest(TEST1, (t, c) => c("foo", t.stringType));
    await runTest(TEST2, (t, c) => c("foo", t.stringType.nullable()));
    await runTest(TEST3, (t, c) => c("foo", t.uint31Type.nullable()));
    await runTest(TEST4, (t, c) => c("foo", t.uint31Type));
    await runTest(TEST5, (t, c) => c("foo", t.uint31Type.nullable()));
    await runTest(TEST6, (t, c) => c("foo", t.uint31Type.nullable()));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}
