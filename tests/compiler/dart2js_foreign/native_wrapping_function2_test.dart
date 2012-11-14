// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_metadata.dart';

typedef void Callback0();
typedef void Callback1(arg1);
typedef void Callback2(arg1, arg2);

@Native("*A")
class A {
  @Native("return closure();")
  foo0(Callback0 closure);

  @Native("return closure(arg1);")
  foo1(Callback1 closure, arg1);

  @Native("return closure(arg1, arg2);")
  foo2(Callback2 closure, arg1, arg2);

  @Native("return closure == (void 0) ? 42 : closure();")
  foo3([Callback0 closure]);
}

@native makeA();

@Native("""
function A() {}
makeA = function(){return new A;};
""")
void setup();

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
