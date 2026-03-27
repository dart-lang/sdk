// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  for (int i = 0; i < 100; i++) {
    testStructAllocateDart();
  }
  print('done');
}

final class Coordinate extends Struct {
  factory Coordinate({double? x, double? y}) {
    final result = Struct.create<Coordinate>();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    return result;
  }

  factory Coordinate.fromTypedList(TypedData typedList) {
    return Struct.create<Coordinate>(typedList);
  }

  @Double()
  external double x;

  @Double()
  external double y;
}

void testStructAllocateDart() {
  final c1 = Coordinate()
    ..x = 10.0
    ..y = 20.0;
  Expect.equals(10.0, c1.x);
  Expect.equals(20.0, c1.y);

  final typedList = Float64List(2);
  typedList[0] = 30.0;
  typedList[1] = 40.0;
  final c2 = Coordinate.fromTypedList(typedList);
  Expect.equals(30.0, c2.x);
  Expect.equals(40.0, c2.y);

  final c3 = Coordinate(x: 50.0, y: 60);
  Expect.equals(50.0, c3.x);
  Expect.equals(60.0, c3.y);
}
