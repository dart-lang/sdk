// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'coordinate.dart';

main() {
  print('start main');

  {
    // Allocates each coordinate separately in c memory.
    final c1 = calloc<Coordinate>()
      ..ref.x = 10.0
      ..ref.y = 10.0;
    final c2 = calloc<Coordinate>()
      ..ref.x = 20.0
      ..ref.y = 20.0
      ..ref.next = c1;
    final c3 = calloc<Coordinate>()
      ..ref.x = 30.0
      ..ref.y = 30.0
      ..ref.next = c2;
    c1.ref.next = c3;

    Coordinate currentCoordinate = c1.ref;
    for (var i in [0, 1, 2, 3, 4]) {
      currentCoordinate = currentCoordinate.next.ref;
      print("${currentCoordinate.x}; ${currentCoordinate.y}");
    }

    calloc.free(c1);
    calloc.free(c2);
    calloc.free(c3);
  }

  {
    // Allocates coordinates consecutively in c memory.
    Pointer<Coordinate> c1 = calloc<Coordinate>(3);
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

    calloc.free(c1);
  }

  {
    // Allocating in native memory returns a pointer.
    final c = calloc<Coordinate>();
    print(c is Pointer<Coordinate>);
    // `.ref` returns a reference which gives access to the fields.
    print(c.ref is Coordinate);
    calloc.free(c);
  }

  print("end main");
}
