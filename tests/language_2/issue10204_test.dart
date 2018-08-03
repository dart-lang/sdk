// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to miscompile
// [A.visitInvokeDynamicMethod].

import "package:expect/expect.dart";

var a = 2;

class Tupe {
  const Tupe();
  get instructionType => a == 2 ? this : new A();
  refine(a, b) => '$a$b';
}

class Node {
  final selector = null;
  var inputs = {"a": const Tupe(), "b": const Tupe()};
  bool isCallOnInterceptor = false;

  getDartReceiver() {
    return isCallOnInterceptor ? inputs["a"] : inputs["b"];
  }
}

class A {
  visitInvokeDynamicMethod(node) {
    var receiverType = node.getDartReceiver().instructionType;
    return receiverType.refine(node.selector, node.selector);
  }
}

main() {
  Expect.equals(
      'nullnull', [new A()].last.visitInvokeDynamicMethod(new Node()));
}
