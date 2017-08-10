// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

import 'dart:async';

const String TEST = r"""
foo() {
  var a = [1, 2, 3];
  return a.first;
}

main() {
  foo();
}
""";

Future runTest() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  return compiler.run(uri).then((_) {
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;
    var commonMasks = closedWorld.commonMasks;
    MemberElement element = findElement(compiler, "foo");
    var mask = typesInferrer.getReturnTypeOfMember(element);
    Expect.equals(commonMasks.uint31Type, simplify(mask, closedWorld));
  });
}

main() {
  asyncStart();
  runTest().then((_) {
    // Make sure that the type is still correct when we do a second compilation.
    return runTest();
  }).whenComplete(asyncEnd);
}
