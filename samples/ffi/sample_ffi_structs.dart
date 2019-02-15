// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'coordinate.dart';

main(List<String> arguments) {
  print('start main');

  {
    // allocates each coordinate separately in c memory
    Coordinate c1 = Coordinate(10.0, 10.0, null);
    Coordinate c2 = Coordinate(20.0, 20.0, c1);
    Coordinate c3 = Coordinate(30.0, 30.0, c2);
    c1.next = c3;

    Coordinate currentCoordinate = c1;
    for (var i in [0, 1, 2, 3, 4]) {
      currentCoordinate = currentCoordinate.next;
      print("${currentCoordinate.x}; ${currentCoordinate.y}");
    }

    c1.free();
    c2.free();
    c3.free();
  }

  {
    // allocates coordinates consecutively in c memory
    Coordinate c1 = Coordinate.allocate(count: 3);
    Coordinate c2 = c1.elementAt(1);
    Coordinate c3 = c1.elementAt(2);
    c1.x = 10.0;
    c1.y = 10.0;
    c1.next = c3;
    c2.x = 20.0;
    c2.y = 20.0;
    c2.next = c1;
    c3.x = 30.0;
    c3.y = 30.0;
    c3.next = c2;

    Coordinate currentCoordinate = c1;
    for (var i in [0, 1, 2, 3, 4]) {
      currentCoordinate = currentCoordinate.next;
      print("${currentCoordinate.x}; ${currentCoordinate.y}");
    }

    c1.free();
  }

  {
    Coordinate c = Coordinate(10, 10, null);
    print(c is Coordinate);
    print(c is ffi.Pointer<ffi.Void>);
    print(c is ffi.Pointer);
    c.free();
  }

  print("end main");
}
