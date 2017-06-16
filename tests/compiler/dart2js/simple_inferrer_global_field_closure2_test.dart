// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

const String TEST = """

method(a) {  // Called only via [foo] with a small integer.
  return a;
}

var foo = method;

returnInt() {
  return foo(54);
}

main() {
  returnInt();
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;

        checkArgument(String functionName, type) {
          dynamic functionElement = findElement(compiler, functionName);
          var signature = functionElement.functionSignature;
          var element = signature.requiredParameters.first;
          Expect.equals(
              type,
              simplify(typesInferrer.getTypeOfElement(element), closedWorld),
              functionName);
        }

        checkArgument('method', closedWorld.commonMasks.uint31Type);
      }));
}
