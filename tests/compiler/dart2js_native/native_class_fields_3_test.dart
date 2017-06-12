// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Verify that we can have fields with names that start with g and s even
// though those names are reserved for getters and setters in minified mode.

// Note: this works because end and send are both in the list of
// reservedNativeProperties.  In general we don't check arbitrary
// names for clashes because it's hard - subclasses can force superclasses
// to rename getters, and that can force unrelated classes to change their
// getters too if they have a property that has the same name.
@Native("A")
class A {
  int bar;
  int g;
  int s;
  int end;
  int gend;
  int send;
  int gettersCalled;
  int settersCalled;
}

void setup() native r"""
function getter() {
  this.gettersCalled++;
  return 42;
}

function setter(x) {
  this.settersCalled++;
  return 314;
}

var descriptor = {
    get: getter,
    set: setter,
    configurable: false,
    writeable: false
};

function A(){
  var a = Object.create(
      { constructor: A },
      { bar: descriptor,
        g: descriptor,
        s: descriptor,
        end: descriptor,
        gend: descriptor,
        send: descriptor
      });
  a.gettersCalled = 0;
  a.settersCalled = 0;
  return a;
}

makeA = function() { return new A; };
self.nativeConstructor(A);
""";

A makeA() native;

class B {}

main() {
  nativeTesting();
  setup();
  confuse(new B());
  var a = makeA();

  Expect.equals(42, confuse(a).bar);
  Expect.equals(42, confuse(a).g);
  Expect.equals(42, confuse(a).s);
  Expect.equals(42, confuse(a).end);
  Expect.equals(42, confuse(a).gend);
  Expect.equals(42, confuse(a).send);
  Expect.equals(271, confuse(a).bar = 271);
  Expect.equals(271, confuse(a).g = 271);
  Expect.equals(271, confuse(a).s = 271);
  Expect.equals(271, confuse(a).end = 271);
  Expect.equals(271, confuse(a).gend = 271);
  Expect.equals(271, confuse(a).send = 271);
  Expect.equals(6, confuse(a).gettersCalled);
  Expect.equals(6, confuse(a).settersCalled);

  Expect.equals(42, a.bar);
  Expect.equals(42, a.g);
  Expect.equals(42, a.s);
  Expect.equals(42, a.end);
  Expect.equals(42, a.gend);
  Expect.equals(42, a.send);
  Expect.equals(271, a.bar = 271);
  Expect.equals(271, a.g = 271);
  Expect.equals(271, a.s = 271);
  Expect.equals(271, a.end = 271);
  Expect.equals(271, a.gend = 271);
  Expect.equals(271, a.send = 271);
  Expect.equals(12, a.gettersCalled);
  Expect.equals(12, a.settersCalled);
}
