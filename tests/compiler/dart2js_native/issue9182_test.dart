// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 9182.  The generative constructor body function
// should not have the interceptor calling convention.

import "dart:_js_helper";
import "package:expect/expect.dart";

@Native("A")
class Foo {
  factory Foo() => makeA();
  // Ensure the instance method 'Bar' uses interceptor convention.
  Bar() => 123;
}

class Bar {
  var _x, _y;
  // Generative constructor with body, having the same name as interceptor
  // convention instance member.
  Bar(x, y) {
    _x = x;
    _y = y;
  }
}

void setup() native r"""
function A(){}
makeA = function() { return new A; };
""";

makeA() native;

main() {
  setup();

  var things = [new Foo(), new Bar(30, 40)];
  var foo = things[0];
  var bar = things[1];

  Expect.equals(123, foo.Bar());  // Ensure that Foo.Bar is used.

  Expect.equals(30, bar._x);
  Expect.equals(40, bar._y);
}
