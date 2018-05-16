// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Move this test to the codegen folder.

import "package:async_helper/async_helper.dart";
import "package:compiler/src/commandline_options.dart";
import "package:compiler/src/constants/values.dart";
import "package:compiler/src/types/types.dart";
import "package:expect/expect.dart";
import '../memory_compiler.dart';

import 'dart:async';

const String TEST1 = r"""
foo(x) {
  return x;
}

bar(x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

main() {
  bar(foo(false));
  bar(foo(foo(false)));
}
""";

Future runTest1() async {
  var result = await runCompiler(
      memorySourceFiles: {'main.dart': TEST1},
      options: [Flags.disableInlining]);
  var compiler = result.compiler;
  var typesInferrer = compiler.globalInference.typesInferrerInternal;
  var closedWorld = typesInferrer.closedWorld;
  var elementEnvironment = closedWorld.elementEnvironment;
  var commonMasks = closedWorld.abstractValueDomain;
  var element = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, 'foo');
  var mask = typesInferrer.getReturnTypeOfMember(element);
  var falseType =
      new ValueTypeMask(commonMasks.boolType, new FalseConstantValue());
  // 'foo' should always return false
  Expect.equals(falseType, mask);
  // the argument to 'bar' is always false
  dynamic bar = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, 'bar');
  compiler.codegenWorldBuilder.forEachParameterAsLocal(bar, (barArg) {
    var barArgMask = typesInferrer.getTypeOfParameter(barArg);
    Expect.equals(falseType, barArgMask);
  });
  var barCode = compiler.backend.getGeneratedCode(bar);
  Expect.isTrue(barCode.contains('"bbb"'));
  Expect.isFalse(barCode.contains('"aaa"'));
}

const String TEST2 = r"""
foo(x) {
  if (x > 3) return true;
  return false;
}

bar(x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

main() {
  bar(foo(5));
  bar(foo(6));
}
""";

Future runTest2() async {
  var result = await runCompiler(
      memorySourceFiles: {'main.dart': TEST2},
      options: [Flags.disableInlining]);
  var compiler = result.compiler;
  var typesInferrer = compiler.globalInference.typesInferrerInternal;
  var commonMasks = typesInferrer.closedWorld.abstractValueDomain;
  var closedWorld = typesInferrer.closedWorld;
  var elementEnvironment = closedWorld.elementEnvironment;
  var element = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, 'foo');
  var mask = typesInferrer.getReturnTypeOfMember(element);
  // Can't infer value for foo's return type, it could be either true or false
  Expect.identical(commonMasks.boolType, mask);
  dynamic bar = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, 'bar');
  compiler.codegenWorldBuilder.forEachParameterAsLocal(bar, (barArg) {
    var barArgMask = typesInferrer.getTypeOfParameter(barArg);
    // The argument to bar should have the same type as the return type of foo
    Expect.identical(commonMasks.boolType, barArgMask);
  });
  var barCode = compiler.backend.getGeneratedCode(bar);
  Expect.isTrue(barCode.contains('"bbb"'));
  // Still must output the print for "aaa"
  Expect.isTrue(barCode.contains('"aaa"'));
}

main() {
  asyncStart();
  runTest1().then((_) {
    return runTest2();
  }).whenComplete(asyncEnd);
}
