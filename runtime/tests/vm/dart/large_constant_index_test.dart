// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --no-background-compilation

import "package:expect/expect.dart";
import 'dart:typed_data';

const large = 1 << 25;

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testArray(List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testUint8Clamped(Uint8ClampedList array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testUint8(Uint8List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testUint16(Uint16List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testUint32(Uint32List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testUint64(Uint64List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testInt8(Int8List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testInt16(Int16List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testInt32(Int32List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testInt64(Int64List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testFloat32(Float32List array) {
  array[large]++;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point")
testFloat64(Float64List array) {
  array[large]++;
}

main() {
  var x;
  for (var i = 0; i < 20; i++) {
    x = new List.filled(large + 1, 0);
    testArray(x);
    Expect.equals(x[large], 1);

    x = new Uint8ClampedList(large + 1);
    testUint8Clamped(x);
    Expect.equals(x[large], 1);

    x = new Uint8List(large + 1);
    testUint8(x);
    Expect.equals(x[large], 1);
    x = new Uint16List(large + 1);
    testUint16(x);
    Expect.equals(x[large], 1);
    x = new Uint32List(large + 1);
    testUint32(x);
    Expect.equals(x[large], 1);
    x = new Uint64List(large + 1);
    testUint64(x);
    Expect.equals(x[large], 1);

    x = new Int8List(large + 1);
    testInt8(x);
    Expect.equals(x[large], 1);
    x = new Int16List(large + 1);
    testInt16(x);
    Expect.equals(x[large], 1);
    x = new Int32List(large + 1);
    testInt32(x);
    Expect.equals(x[large], 1);
    x = new Int64List(large + 1);
    testInt64(x);
    Expect.equals(x[large], 1);

    x = new Float32List(large + 1);
    testFloat32(x);
    Expect.equals(x[large], 1);
    x = new Float64List(large + 1);
    testFloat64(x);
    Expect.equals(x[large], 1);
  }
}
