// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void Callback0();
typedef void Callback1(arg1);
typedef void Callback2(arg1, arg2);

class A native "*A" {
  foo0(Callback0 closure) native "return closure();";
  foo1(Callback1 closure, arg1) native "return closure(arg1);";
  foo2(Callback2 closure, arg1, arg2) native "return closure(arg1, arg2);";
  foo3([Callback0 closure]) native
      "return closure == (void 0) ? 42 : closure();";
}

makeA() native;

void setup() native """
function A() {}
makeA = function(){return new A;};
""";


main() {
  setup();
  var a = makeA();
  Expect.equals(42, a.foo0(() => 42));
  Expect.equals(43, a.foo1((arg1) => arg1, 43));
  Expect.equals(44, a.foo2((arg1, arg2) => arg1 + arg2, 21, 23));
  Expect.equals(42, a.foo3());
  Expect.equals(43, a.foo3(() => 43));

  A aa = a;
  Expect.equals(42, aa.foo0(() => 42));
  Expect.equals(43, aa.foo1((arg1) => arg1, 43));
  Expect.equals(44, aa.foo2((arg1, arg2) => arg1 + arg2, 21, 23));
  Expect.equals(42, aa.foo3());
  Expect.equals(43, aa.foo3(() => 43));
}
