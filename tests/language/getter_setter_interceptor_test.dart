// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int length = 0;
}

class B {
  int length = 0;
  foo(receiver) {
    length++;
    return receiver.length++;
  }

  bar(receiver) {
    ++length;
    return ++receiver.length;
  }
}

main() {
  var a = new A();
  var b = new B();
  var c = [1, 2, 3];

  Expect.equals(3, b.foo(c));
  Expect.equals(5, b.bar(c));
  Expect.equals(5, c.length);

  Expect.equals(0, b.foo(a));
  Expect.equals(2, b.bar(a));
  Expect.equals(2, a.length);

  Expect.equals(4, b.length);
}
