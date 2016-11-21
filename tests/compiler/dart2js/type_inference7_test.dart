// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';
import 'dart:async';

const String TEST = r"""
foo(x, [y]) => y;

main() {
  assert(foo('Hi', true), foo(true));
  foo(1);
}
""";

Future runTest() async {
  Uri uri = new Uri(scheme: 'source');
  {
    // Assertions enabled:
    var compiler = compilerFor(TEST, uri, enableUserAssertions: true);
    await compiler.run(uri);
    var commonMasks = compiler.closedWorld.commonMasks;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var foo = findElement(compiler, "foo");
    // Return type is null|bool.
    var mask = typesInferrer.getReturnTypeOfElement(foo);
    Expect.isTrue(mask.isNullable);
    Expect.equals(commonMasks.boolType, simplify(mask.nonNullable(), compiler));
    // First parameter is uint31|String|bool.
    var mask1 = typesInferrer.getTypeOfElement(foo.parameters[0]);
    Expect.isTrue(mask1.isUnion);
    var expectedTypes = new Set.from(
        [commonMasks.uint31Type, commonMasks.stringType, commonMasks.boolType]);
    for (var typeMask in mask1.disjointMasks) {
      Expect.isFalse(typeMask.isNullable);
      var simpleType = simplify(typeMask, compiler);
      Expect.isTrue(expectedTypes.remove(simpleType), "$simpleType");
    }
    Expect.isTrue(expectedTypes.isEmpty);
    // Second parameter is bool or null.
    var mask2 = typesInferrer.getTypeOfElement(foo.parameters[1]);
    Expect.isTrue(mask2.isNullable);
    Expect.equals(
        commonMasks.boolType, simplify(mask2.nonNullable(), compiler));
  }

  {
    // Assertions disabled:
    var compiler = compilerFor(TEST, uri, enableUserAssertions: false);
    await compiler.run(uri);
    var commonMasks = compiler.closedWorld.commonMasks;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var foo = findElement(compiler, "foo");
    // Return type is null.
    var mask = typesInferrer.getReturnTypeOfElement(foo);
    Expect.isTrue(mask.isNullable);
    Expect.isTrue(mask.nonNullable().isEmpty);
    // First parameter is uint31.
    var mask1 = typesInferrer.getTypeOfElement(foo.parameters[0]);
    Expect.isFalse(mask1.isNullable);
    Expect.equals(commonMasks.uint31Type, simplify(mask1, compiler));
    // Second parameter is null.
    var mask2 = typesInferrer.getTypeOfElement(foo.parameters[1]);
    Expect.isTrue(mask2.isNullable);
    Expect.isTrue(simplify(mask2.nonNullable(), compiler).isEmpty);
  }
}

main() {
  asyncStart();
  runTest().then((_) {
    // Make sure that the type is still correct when we do a second compilation.
    return runTest();
  }).whenComplete(asyncEnd);
}
