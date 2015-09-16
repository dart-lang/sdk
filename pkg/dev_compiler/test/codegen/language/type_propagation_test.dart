// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2js used to have an infinite loop in its type propagation
// algorithm due to types becoming broader instead of narrower.

import "package:expect/expect.dart";

class A {
  resolveSend(node) {
    if (node == null) {
      return [new B()][0];
    } else {
      return [new B(), new A()][1];
    }
  }

  visitSend(node) {
    var target = resolveSend(node);

    if (false) {
      if (false) {
        target = target.getter;
        if (false) {
          target = new Object();
        }
      }
    }
    return true ? target : null;
  }
}

var a = 43;

class B {
  var getter = a == 42 ? new A() : null;
}

main() {
  Expect.isTrue(new A().visitSend(new A()) is A);
  Expect.isTrue(new A().visitSend(null) is B);
}
