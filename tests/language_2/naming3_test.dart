// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var __PROTO__ = 499;
  var constructor = 1;
  var prototype = 2;
}

// TODO(jmesserly): changed this test to avoid shadowing a field with a getter,
// which DDC doesn't currently support, see:
// https://github.com/dart-lang/dev_compiler/issues/52
class A2 {
  get __PROTO__ => 499;
  get constructor => 1;
  get prototype => 2;
}

class B extends A2 {
  get __PROTO__ => 42;
  get constructor => 3;
  get prototype => 4;
}

main() {
  var a = new A();
  var a2 = new A2();
  var b = new B();
  var list = <dynamic>[a, a2, b];
  for (int i = 0; i < list.length; i++) {
    var proto = list[i].__PROTO__;
    var constructor = list[i].constructor;
    var prototype = list[i].prototype;
    if (i < 2) {
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
