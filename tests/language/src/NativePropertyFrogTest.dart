// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Properties on hidden native classes.

class A native "*A" {

  // Setters and getters should be similar to these methods:
  int getX() native 'return this._x;';
  void setX(int value) native 'this._x = value;';

  int get X() native;
  set X(int value) native;

  int get Y() native;
  set Y(int value) native;

  int get Z() native 'return this._z;';
  set Z(int value) native 'this._z = value;';
}

A makeA() native { return new A(); }

void setup() native """
function A() {}

Object.defineProperty(A.prototype, "X", {
  get: function () { return this._x; },
  set: function (v) { this._x = v; }
});

makeA = function(){return new A;};
""";


main() {
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
}
