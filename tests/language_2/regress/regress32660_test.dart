// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// noSuchMethod does not overwrite actual implementations, so if an
// implemetation of a member exists that doesn't fulfill the interface it's
// an error.
// On the other hand, if no implementation exists,
// noSuchMethod will take its place and everything is okay.

class B {
  foo(int x, // force formatter to not combine these lines.
          {int y} //# 02: compile-time error
          ) =>
      x;
}

class C extends B {
  foo(int x, // force formatter to not combine these lines.
      {int y} //# 01: compile-time error
      );
  bar();

  noSuchMethod(i) {
    print("No such method!");
    return 42;
  }
}

abstract class D {
  foo(int x, // force formatter to not combine these lines.
      {int y} //# 03: ok
      );
}

abstract class E {
  foo(int x, // force formatter to not combine these lines.
      {int y} //# 04: ok
      );
}

class F extends D implements E {
  noSuchMethod(i) {
    print("No such method!");
    return 42;
  }
}

class G {
  foo(int x, // force formatter to not combine these lines.
          {int y} //# 05: ok
          ) =>
      x;
}

class H {
  foo(int x, // force formatter to not combine these lines.
          {int y} //# 06: compile-time error
          ) =>
      x;
}

class I extends G implements H {
  noSuchMethod(i) {
    print("No such method: $i!");
    return 42;
  }
}

main() {
  var c = new C();
  c.foo(123);
  c.bar();
  var f = new F();
  f.foo(42);
  var i = new I();
  i.foo(42);
}
