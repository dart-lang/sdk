// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'compiler_helper.dart';

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
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;

        checkReturnInClass(String className, String methodName, type) {
          dynamic cls = findElement(compiler, className);
          var element = cls.lookupLocalMember(methodName);
          Expect.equals(type, typesInferrer.getReturnTypeOfMember(element));
        }

        checkReturnInClass(
            'A', '+', typesInferrer.closedWorld.commonMasks.uint31Type);
      }));
}
