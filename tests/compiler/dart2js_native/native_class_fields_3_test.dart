// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

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
      { constructor: { name: 'A'}},
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
""";

A makeA() native;

class B {
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  setup();
  var both = [makeA(), new B()];
  var foo = both[inscrutable(0)];
  Expect.equals(42, foo.bar);
  Expect.equals(42, foo.g);
  Expect.equals(42, foo.s);
  Expect.equals(42, foo.end);
  Expect.equals(42, foo.gend);
  Expect.equals(42, foo.send);
  Expect.equals(271, foo.bar = 271);
  Expect.equals(271, foo.g = 271);
  Expect.equals(271, foo.s = 271);
  Expect.equals(271, foo.end = 271);
  Expect.equals(271, foo.gend = 271);
  Expect.equals(271, foo.send = 271);
  Expect.equals(6, foo.gettersCalled);
  Expect.equals(6, foo.settersCalled);
}
