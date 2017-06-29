// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import "package:compiler/src/constants/values.dart";
import "package:compiler/src/types/types.dart";
import "package:expect/expect.dart";
import 'compiler_helper.dart';

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

Future runTest1() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST1, uri);
  return compiler.run(uri).then((_) {
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var commonMasks = typesInferrer.closedWorld.commonMasks;
    var element = findElement(compiler, "foo");
    var mask = typesInferrer.getReturnTypeOfMember(element);
    var falseType =
        new ValueTypeMask(commonMasks.boolType, new FalseConstantValue());
    // 'foo' should always return false
    Expect.equals(falseType, mask);
    // the argument to 'bar' is always false
    dynamic bar = findElement(compiler, "bar");
    var barArg = bar.parameters.first;
    var barArgMask = typesInferrer.getTypeOfParameter(barArg);
    Expect.equals(falseType, barArgMask);
    var barCode = compiler.backend.getGeneratedCode(bar);
    Expect.isTrue(barCode.contains('"bbb"'));
    Expect.isFalse(barCode.contains('"aaa"'));
  });
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

Future runTest2() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST2, uri);
  return compiler.run(uri).then((_) {
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var commonMasks = typesInferrer.closedWorld.commonMasks;
    var element = findElement(compiler, "foo");
    var mask = typesInferrer.getReturnTypeOfMember(element);
    // Can't infer value for foo's return type, it could be either true or false
    Expect.identical(commonMasks.boolType, mask);
    dynamic bar = findElement(compiler, "bar");
    var barArg = bar.parameters.first;
    var barArgMask = typesInferrer.getTypeOfParameter(barArg);
    // The argument to bar should have the same type as the return type of foo
    Expect.identical(commonMasks.boolType, barArgMask);
    var barCode = compiler.backend.getGeneratedCode(bar);
    Expect.isTrue(barCode.contains('"bbb"'));
    // Still must output the print for "aaa"
    Expect.isTrue(barCode.contains('"aaa"'));
  });
}

main() {
  asyncStart();
  runTest1().then((_) {
    return runTest2();
  }).whenComplete(asyncEnd);
}
