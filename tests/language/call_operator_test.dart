// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// simple test with no types in signature
class A1 {
  call() => 42;
}

// same test, include return type
class A2 {
  int call() => 35;
}

class B {
  call() => 28;
}

// A call() operator can have any arity
class C {
  call(arg) => 7 * arg;
}

// Test named arguments
class D {
  call([arg = 6]) => 7 * arg;
}

// Non-trivial method body combination of positional and named.
class E {
  String call(String str, {int count: 1}) {
    StringBuffer buffer = new StringBuffer();
    for (var i = 0; i < count; i++) {
      buffer.write(str);
      if (i < count - 1) {
        buffer.write(":");
      }
    }
    return buffer.toString();
  }
}

main() {
  var a1 = new A1();
  Expect.equals(42, a1());
  Expect.equals(42, a1.call());

  var a2 = new A2();
  Expect.equals(35, a2());
  Expect.equals(35, a2.call());

  var b = new B();
  Expect.equals(28, b());
  Expect.equals(28, b.call());

  var c = new C();
  Expect.equals(42, c(6));
  Expect.equals(42, c.call(6));

  var d = new D();
  Expect.equals(42, d());
  Expect.equals(7, d(1));
  Expect.equals(14, d(2));
  Expect.equals(42, d.call());
  Expect.equals(7, d.call(1));
  Expect.equals(14, d.call(2));

  var e = new E();
  Expect.equals("foo", e("foo"));
  Expect.equals("foo:foo", e("foo", count: 2));
  Expect.equals("foo:foo:foo", e("foo", count: 3));
  Expect.equals("foo", e.call("foo"));
  Expect.equals("foo:foo", e.call("foo", count: 2));
  Expect.equals("foo:foo:foo", e.call("foo", count: 3));

  Expect.isTrue(a1 is Function);
  Expect.isTrue(e is Function);
}
