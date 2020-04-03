// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'coordinate.dart';

main() {
  print('start main');

  {
    // Allocates each coordinate separately in c memory.
    Coordinate c1 = Coordinate.allocate(10.0, 10.0, nullptr);
    Coordinate c2 = Coordinate.allocate(20.0, 20.0, c1.addressOf);
    Coordinate c3 = Coordinate.allocate(30.0, 30.0, c2.addressOf);
    c1.next = c3.addressOf;

    Coordinate currentCoordinate = c1;
    for (var i in [0, 1, 2, 3, 4]) {
      currentCoordinate = currentCoordinate.next.ref;
      print("${currentCoordinate.x}; ${currentCoordinate.y}");
    }

    free(c1.addressOf);
    free(c2.addressOf);
    free(c3.addressOf);
  }

  {
    // Allocates coordinates consecutively in c memory.
    Pointer<Coordinate> c1 = allocate<Coordinate>(count: 3);
    Pointer<Coordinate> c2 = c1.elementAt(1);
    Pointer<Coordinate> c3 = c1.elementAt(2);
    c1.ref.x = 10.0;
    c1.ref.y = 10.0;
    c1.ref.next = c3;
    c2.ref.x = 20.0;
    c2.ref.y = 20.0;
    c2.ref.next = c1;
    c3.ref.x = 30.0;
    c3.ref.y = 30.0;
    c3.ref.next = c2;

    Coordinate currentCoordinate = c1.ref;
    for (var i in [0, 1, 2, 3, 4]) {
      currentCoordinate = currentCoordinate.next.ref;
      print("${currentCoordinate.x}; ${currentCoordinate.y}");
    }

    free(c1);
  }

  {
    Coordinate c = Coordinate.allocate(10, 10, nullptr);
    print(c is Coordinate);
    print(c is Pointer<Void>);
    print(c is Pointer);
    free(c.addressOf);
  }

  print("end main");
}
