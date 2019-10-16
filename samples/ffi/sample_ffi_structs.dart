// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'coordinate.dart';

main(List<String> arguments) {
  print('start main');

  {
    // allocates each coordinate separately in c memory
    Coordinate c1 = Coordinate(10.0, 10.0, null);
    Coordinate c2 = Coordinate(20.0, 20.0, c1);
    Coordinate c3 = Coordinate(30.0, 30.0, c2);
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
    // allocates coordinates consecutively in c memory
    Coordinate c1 = Coordinate.allocate(count: 3);
    Coordinate c2 = c1.elementAt(1);
    Coordinate c3 = c1.elementAt(2);
    c1.x = 10.0;
    c1.y = 10.0;
    c1.next = c3.addressOf;
    c2.x = 20.0;
    c2.y = 20.0;
    c2.next = c1.addressOf;
    c3.x = 30.0;
    c3.y = 30.0;
    c3.next = c2.addressOf;

    Coordinate currentCoordinate = c1;
    for (var i in [0, 1, 2, 3, 4]) {
      currentCoordinate = currentCoordinate.next.ref;
      print("${currentCoordinate.x}; ${currentCoordinate.y}");
    }

    free(c1.addressOf);
  }

  {
    Coordinate c = Coordinate(10, 10, null);
    print(c is Coordinate);
    print(c is Pointer<Void>);
    print(c is Pointer);
    free(c.addressOf);
  }

  print("end main");
}
