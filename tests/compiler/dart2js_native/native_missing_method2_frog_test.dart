// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

@Native("A")
class A {}

A makeA() native;

void setup() native """
function A() {};
A.prototype.foo = function() { return  42; }
makeA = function() { return new A; }
self.nativeConstructor(A);
""";

class B {
  foo() {
    return 42;
  }
}

class C {
  // By having two 'foo' defined in the application, Frog will mangle
  // all calls to 'foo', which makes this test pass.
  foo(x) {
    return 43;
  }
}

typedContext() {
  A a = makeA();
  Expect.throws(() => a.foo(), (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo, (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo = 4, (e) => e is NoSuchMethodError);
}

untypedContext() {
  var a = confuse(makeA());
  Expect.throws(() => a.foo(), (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo, (e) => e is NoSuchMethodError);
  Expect.throws(() => a.foo = 4, (e) => e is NoSuchMethodError);
}

main() {
  nativeTesting();
  setup();
  confuse(new B()).foo();
  confuse(new C()).foo(1);
  typedContext();
  untypedContext();
}
