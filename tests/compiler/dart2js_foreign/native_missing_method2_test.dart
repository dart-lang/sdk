// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@native("*A")
class A {
}

@native makeA();

@native("""
function A() {};
A.prototype.foo = function() { return  42; }
makeA = function() { return new A; }
""")
void setup();

class B {
  foo() { return 42; }
}

class C {
  // By having two 'foo' defined in the application, Frog will mangle
  // all calls to 'foo', which makes this test pass.
  foo(x) { return 43; }
}

typedContext() {
  var things = [ makeA(), new B() ];
  A a = things[0];
  Expect.throws(() => a.foo(),
                (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo,
                (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo = 4,
                (e) => e is NoSuchMethodError);
}

untypedContext() {
  var things = [ makeA(), new B() ];
  var a = things[0];
  Expect.throws(() => a.foo(),
                (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo,
                (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo = 4,
                (e) => e is NoSuchMethodError);
}

main() {
  setup();
  typedContext();
  untypedContext();
}
