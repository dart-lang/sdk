// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:expect/expect.dart';

main() {
  // constructor
  {
    var point = new Point(0, 0);
    Expect.equals(0, point.x);
    Expect.equals(0, point.y);
    Expect.equals('Point(0, 0)', '$point');
  }

  // constructor X
  {
    var point = new Point<int>(10, 0);
    Expect.equals(10, point.x);
    Expect.equals(0, point.y);
    Expect.equals('Point(10, 0)', '$point');
  }

  // constructor X Y
  {
    var point = new Point<int>(10, 20);
    Expect.equals(10, point.x);
    Expect.equals(20, point.y);
    Expect.equals('Point(10, 20)', '$point');
  }

  // constructor X Y double
  {
    var point = new Point<double>(10.5, 20.897);
    Expect.equals(10.5, point.x);
    Expect.equals(20.897, point.y);
    Expect.equals('Point(10.5, 20.897)', '$point');
  }

  // constructor X Y NaN
  {
    var point = new Point(double.NAN, 1000);
    Expect.isTrue(point.x.isNaN);
    Expect.equals(1000, point.y);
    Expect.equals('Point(NaN, 1000)', '$point');
  }

  // squaredDistanceTo
  {
    var a = new Point(7, 11);
    var b = new Point(3, -1);
    Expect.equals(160, a.squaredDistanceTo(b));
    Expect.equals(160, b.squaredDistanceTo(a));
  }

  // distanceTo
  {
    var a = new Point(-2, -3);
    var b = new Point(2, 0);
    Expect.equals(5, a.distanceTo(b));
    Expect.equals(5, b.distanceTo(a));
  }

  // subtract
  {
    var a = new Point(5, 10);
    var b = new Point(2, 50);
    Expect.equals(new Point(3, -40), a - b);
  }

  // add
  {
    var a = new Point(5, 10);
    var b = new Point(2, 50);
    Expect.equals(new Point(7, 60), a + b);
  }

  // hashCode
  {
    var a = new Point(0, 1);
    var b = new Point(0, 1);
    Expect.equals(b.hashCode, a.hashCode);

    var c = new Point(1, 0);
    Expect.isFalse(a.hashCode == c.hashCode);
  }

  // magnitude
  {
    var a = new Point(5, 10);
    var b = new Point(0, 0);
    Expect.equals(a.distanceTo(b), a.magnitude);
    Expect.equals(0, b.magnitude);

    var c = new Point(-5, -10);
    Expect.equals(a.distanceTo(b), c.magnitude);
  }
}
