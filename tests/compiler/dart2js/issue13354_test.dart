// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

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
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;
        var commonMasks = closedWorld.commonMasks;

        checkReturn(String name, type) {
          MemberElement element = findElement(compiler, name);
          Expect.equals(
              type,
              simplify(
                  typesInferrer.getReturnTypeOfMember(element), closedWorld),
              name);
        }

        checkReturnInClass(String className, String methodName, type) {
          dynamic cls = findElement(compiler, className);
          var element = cls.lookupLocalMember(methodName);
          Expect.equals(
              type,
              simplify(
                  typesInferrer.getReturnTypeOfMember(element), closedWorld));
        }

        checkReturn('bar', commonMasks.uint31Type);
        checkReturn('baz', commonMasks.functionType);

        checkReturnInClass('A', 'foo', commonMasks.uint31Type);
        checkReturnInClass('B', 'foo', commonMasks.functionType);
      }));
}
