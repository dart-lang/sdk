// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Simple {
    int x;
    Simple(this.x) { }
    Simple.foo(x,y) : this(x + y);
    Simple.bar(x,y,z) : this.foo(x + y, z);
}

class Point {
  final num x;
  final num y;
  Point() : this.coord(0, 0); // Redirects to Point.coord.
  Point.coord(this.x, this.y) {}
}

class A {
  var x;
  A() : this.named(499);
  A.named(this.x) {}
}

class B extends A {
  B() : super() {}
}

class C {
  int x;
  const C() : this.x = 123;
  C.foo() : this();
}

