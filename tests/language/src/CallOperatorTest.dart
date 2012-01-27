// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// simple test with no types in signature
class A1 {
  operator call() => 42;
}

// same test, include return type
class A2 {
  int operator call() => 35;
}

class B {
  call() => 28; // expect warning, should use 'operator call'
}

// A call() operator can have any arity
class C {
  operator call(arg) => 7 * arg;
}

// Test named arguments
class D {
  operator call([arg=6]) => 7 * arg;
}

// non-trvial method body combination of positional and named
class E {
  String operator call(String str, [int count=1]) {
    String result = "";
    for (var i = 0; i < count; i++) {
      result += str;
      if (i < count -1) {
        result += ':';
      }
    }
    return result;
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
  Expect.equals(14, d(arg:2));
  Expect.equals(42, d.call());
  Expect.equals(7, d.call(1));
  Expect.equals(14, d.call(arg:2));

  var e = new E();
  Expect.equals("foo", e("foo"));
  Expect.equals("foo:foo", e("foo", 2));
  Expect.equals("foo:foo:foo", e("foo", count:3));
  Expect.equals("foo", e.call("foo"));
  Expect.equals("foo:foo", e.call("foo", 2));
  Expect.equals("foo:foo:foo", e.call("foo", count:3));
}
