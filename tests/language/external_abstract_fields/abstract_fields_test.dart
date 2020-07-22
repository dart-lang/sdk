// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Checks that abstract instance variable declarations are allowed.

import "package:expect/expect.dart";

// Valid declarations for abstract class.
abstract class C {
  abstract int x1, x2;
  abstract var y1, y2, y3; // infers dynamic.
  abstract final z;
  abstract final int u1, u2;
  abstract covariant int v1, v2, v3;
  abstract covariant var w;
}

class D {
  int x1, x2;
  var y1, y2, y3;
  var z;
  int u1, u2;
  covariant int v1, v2, v3;
  covariant var w;
  D() :
      x1 = 0,
      x2 = 0,
      y1 = 1,
      y2 = 1,
      y3 = 1,
      z = 2,
      u1 = 3,
      u2 = 3,
      v1 = 4,
      v2 = 4,
      v3 = 4,
      w = 5;
}

/// Valid implementation of abstract interface.
class E extends D implements C {}

// Valid declarations when superclass has implementation.
class F extends D { // Class is not abstract.
  abstract int x1, x2;
  abstract var y1, y2, y3;
  abstract final z;
  abstract final int u1, u2;
  abstract covariant int v1, v2, v3;
  abstract covariant var w;
}

// Records accesses.
class Logger {
  Symbol? lastName;
  String _x = "x";
  int _y = 0;
  String get x {
    lastName = #x;
    return _x;
  }
  set x(String value) {
    lastName = #x;
    _x = value;
  }
  int get y {
    lastName = #y;
    return _y;
  }
  set y(int value) {
    lastName = #y;
    _y = value;
  }
}

/// Check that abstract declarations do not shadow implementation.
class Override extends Logger {
  abstract String x;
  abstract final int y;
}

void main() {
  C c = E();
  Expect.equals(0, c.x1);
  Expect.equals(0, c.x2);
  Expect.equals(1, c.y1);
  Expect.equals(1, c.y2);
  Expect.equals(1, c.y3);
  Expect.equals(2, c.z);
  Expect.equals(3, c.u1);
  Expect.equals(3, c.u2);
  Expect.equals(4, c.v1);
  Expect.equals(4, c.v2);
  Expect.equals(4, c.v3);
  Expect.equals(5, c.w);
  c.x1 = 6;
  Expect.equals(6, c.x1);
  c.y2 = 7;
  Expect.equals(7, c.y2);
  c.v3 = 8;
  Expect.equals(8, c.v3);
  c.w = 9;
  Expect.equals(9, c.w);

  // Class F is not abstract and can be instantiated.
  F f = F();
  Expect.equals(0, f.x1);
  Expect.equals(0, f.x2);
  Expect.equals(1, f.y1);
  Expect.equals(1, f.y2);
  Expect.equals(1, f.y3);
  Expect.equals(2, f.z);
  Expect.equals(3, f.u1);
  Expect.equals(3, f.u2);
  Expect.equals(4, f.v1);
  Expect.equals(4, f.v2);
  Expect.equals(4, f.v3);
  Expect.equals(5, f.w);
  f.x1 = 6;
  Expect.equals(6, f.x1);
  f.y2 = 7;
  Expect.equals(7, f.y2);
  f.v3 = 8;
  Expect.equals(8, f.v3);
  f.w = 9;
  Expect.equals(9, f.w);

  // Check that abstract declarations do not shadow superclass implementation.
  Override o = Override();
  Expect.equals("x", o.x);
  Expect.equals(#x, o.lastName);
  Expect.equals(0, o.y);
  Expect.equals(#y, o.lastName);
  o.x = "b";
  Expect.equals(#x, o.lastName);
  o.y = 42;
  Expect.equals(#y, o.lastName);
  Expect.equals("b", o.x);
  Expect.equals(#x, o.lastName);
  Expect.equals(42, o.y);
  Expect.equals(#y, o.lastName);
}
