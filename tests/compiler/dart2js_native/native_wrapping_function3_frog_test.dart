// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

typedef void Callback0();
typedef void Callback1(arg1);
typedef void Callback2(arg1, arg2);

@Native("A")
class A {
  foo1(Callback1 closure, [arg1 = 0]) native;
  foo2(Callback2 closure, [arg1 = 0, arg2 = 1]) native;
}

A makeA() native;

void setup() native """
function A() {}
A.prototype.foo1 = function(closure, arg1) { return closure(arg1); };
A.prototype.foo2 = function(closure, arg1, arg2) {
  return closure(arg1, arg2);
};
makeA = function(){return new A;};
self.nativeConstructor(A);
""";

main() {
  nativeTesting();
  setup();
  var a = makeA();
  // Statically known receiver type calls.
  Expect.equals(43, a.foo1((arg1) => arg1, 43));
  Expect.equals(0, a.foo1((arg1) => arg1));

  Expect.equals(44, a.foo2((arg1, arg2) => arg1 + arg2, 21, 23));
  Expect.equals(22, a.foo2((arg1, arg2) => arg1 + arg2, 21));

  // Dynamic calls.
  Expect.equals(43, confuse(a).foo1((arg1) => arg1, 43));
  Expect.equals(0, confuse(a).foo1((arg1) => arg1));

  Expect.equals(44, confuse(a).foo2((arg1, arg2) => arg1 + arg2, 21, 23));
  Expect.equals(22, confuse(a).foo2((arg1, arg2) => arg1 + arg2, 21));
}
