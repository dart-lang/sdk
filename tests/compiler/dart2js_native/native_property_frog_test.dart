// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Properties on hidden native classes.

import 'native_testing.dart';

@Native("A")
class A {
  // Setters and getters should be similar to these methods:
  int getX() => JS('int', '#._x', this);
  void setX(int value) {
    JS('void', '#._x = #', this, value);
  }

  int get X native;
  set X(int value) native;

  int get Y native;
  set Y(int value) native;

  int get Z => JS('int', '#._z', this);
  set Z(int value) {
    JS('void', '#._z = #', this, value);
  }
}

A makeA() native;

void setup() {
  JS('', r"""
(function(){
  function A() {}

  Object.defineProperty(A.prototype, "X", {
    get: function () { return this._x; },
    set: function (v) { this._x = v; }
  });

  makeA = function(){return new A()};

  self.nativeConstructor(A);
})()""");
}

main() {
  nativeTesting();
  setup();

  var a = makeA();

  a.setX(5);
  Expect.equals(5, a.getX());

  a.X = 10;
  a.Y = 20;
  a.Z = 30;

  Expect.equals(10, a.X);
  Expect.equals(20, a.Y);
  Expect.equals(30, a.Z);

  confuse(a).setX(6);
  Expect.equals(6, confuse(a).getX());

  Expect.equals(6, confuse(a).X);
  Expect.equals(20, confuse(a).Y);
  Expect.equals(30, confuse(a).Z);
}
