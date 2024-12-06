// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--deterministic --optimization-counter-threshold=50

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  for (int i = 0; i < 100; i++) {
    testStructAllocateDart();
    testUseCreateDirectly();
    testOffsets();
    testOutOfBounds();
    testUnion();
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

  factory Coordinate.fromTypedList(TypedData typedList, [int offset = 0]) {
    return Struct.create<Coordinate>(typedList, offset);
  }

  @Double()
  external double x;

  @Double()
  external double y;
}

void testStructAllocateDart() {
  final c1 =
      Coordinate()
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

final class SomeStruct extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;
}

void testUseCreateDirectly() {
  final c1 =
      Struct.create<SomeStruct>()
        ..x = 10.0
        ..y = 20.0;
  Expect.equals(10.0, c1.x);
  Expect.equals(20.0, c1.y);
}

void testOffsets() {
  const length = 100;
  final typedList = Float64List(length * 2);
  for (int i = 0; i < length * 2; i++) {
    typedList[i] = i.toDouble();
  }
  final size = sizeOf<Coordinate>();
  var structs = [
    for (var i = 0; i < length; i++)
      Coordinate.fromTypedList(
        typedList,
        i * size ~/ typedList.elementSizeInBytes,
      ),
  ];
  for (int i = 0; i < length; i++) {
    Expect.approxEquals(structs[i].x, 2 * i);
    Expect.approxEquals(structs[i].y, 2 * i + 1);
  }
}

void testOutOfBounds() {
  final typedList = Uint8List(3 * sizeOf<Double>());
  final c1 =
      Coordinate.fromTypedList(typedList)
        ..x = 4
        ..y = 6;
  final view = Uint8List.view(typedList.buffer, 16);
  Expect.equals(8, view.lengthInBytes);
  Expect.throws<RangeError>(() {
    Coordinate.fromTypedList(view)
      ..x = 6
      ..y = 8;
  });
  Expect.throws<RangeError>(() {
    Coordinate.fromTypedList(typedList, 16)
      ..x = 6
      ..y = 8;
  });
  Expect.throws<RangeError>(() {
    // Negative offsets are not allowed. One should access the ByteBuffer to
    // apply a negative offset if this is wanted.
    Coordinate.fromTypedList(view, -1)
      ..x = 6
      ..y = 8;
  });
  Expect.approxEquals(c1.x, 4);
  Expect.approxEquals(c1.y, 6);
}

final class MyUnion extends Union {
  @Int32()
  external int a;

  @Float()
  external double b;

  /// Allocates a new [TypedData] of size `sizeOf<MyUnion>()` and wraps it in
  /// [MyUnion].
  factory MyUnion.a(int a) {
    return Union.create<MyUnion>()..a = a;
  }

  /// Allocates a new [TypedData] of size `sizeOf<MyUnion>()` and wraps it in
  /// [MyUnion].
  factory MyUnion.b(double b) {
    return Union.create<MyUnion>()..b = b;
  }

  /// Constructs a [MyUnion] view on [typedList].
  factory MyUnion.fromTypedData(TypedData typedList) {
    return Union.create<MyUnion>(typedList);
  }
}

final class MyUnion2 extends Union {
  @Int32()
  external int a;

  @Float()
  external double b;
}

void testUnion() {
  final myUnion = MyUnion.a(123);
  Expect.equals(123, myUnion.a);
  Expect.approxEquals(1.723597111119525e-43, myUnion.b);

  final myUnion2 = Union.create<MyUnion2>()..a = 123;
  Expect.equals(123, myUnion2.a);
  Expect.approxEquals(1.723597111119525e-43, myUnion2.b);
}
