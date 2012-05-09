// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  var __PROTO__ = 499;
  var constructor = 1;
  var prototype = 2;
}

class B extends A {
  get __PROTO__() => 42;
  get constructor() => 3;
  get prototype() => 4;
}

main() {
  var a = new A();
  var b = new B();
  var list = [a, b];
  for (int i = 0; i < list.length; i++) {
    var proto = list[i].__PROTO__;
    var constructor = list[i].constructor;
    var prototype = list[i].prototype;
    if (i == 0) {
      Expect.equals(499, proto);
      Expect.equals(1, constructor);
      Expect.equals(2, prototype);
    } else {
      Expect.equals(42, proto);
      Expect.equals(3, constructor);
      Expect.equals(4, prototype);
    }
  }
}
