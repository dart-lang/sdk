// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class I {
  void foo();
}

class T1 implements I {
  void foo() {}
}

class T2 implements I {
  void foo() {}
}

class Point {
  final I x;

  const Point(I x) : this.x = x;

  Point newPoint1() => new Point(x);
  Point newPoint2() => new Point(x);
}

getX(var point) {
  point.x;
}

main() {
  var a = new Point(new T1());

  print(a.x);

  var c = new Point(new T2());

  c.x.foo();

  getX(a.newPoint1());
  getX(a.newPoint2());
}
