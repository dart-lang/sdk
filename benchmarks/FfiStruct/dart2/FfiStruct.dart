// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmark for ffi struct field stores and loads.
//
// Only tests a single field because the FfiMemory benchmark already tests loads
// and stores of different field sizes.

// @dart=2.9

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

//
// Struct field store (plus Pointer elementAt and load).
//

void doStoreInt32(Pointer<VeryLargeStruct> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i].c = 1;
  }
}

//
// Struct field load (plus Pointer elementAt and load).
//

int doLoadInt32(Pointer<VeryLargeStruct> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i].c;
  }
  return x;
}

//
// Benchmark fixture.
//

// Number of repeats: 1000
//  * CPU: Intel(R) Xeon(R) Gold 6154
//    * Architecture: x64
//      * 150000 - 465000 us (without optimizations)
//      * 14 - ??? us (expected with optimizations, on par with typed data)
const N = 1000;

class FieldLoadStore extends BenchmarkBase {
  Pointer<VeryLargeStruct> pointer;
  FieldLoadStore() : super('FfiStruct.FieldLoadStore');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreInt32(pointer, N);
    final int x = doLoadInt32(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

//
// Main driver.
//

void main() {
  final benchmarks = [
    () => FieldLoadStore(),
  ];
  for (final benchmark in benchmarks) {
    benchmark().report();
  }
}

//
// Test struct.
//
class VeryLargeStruct extends Struct {
  @Int8()
  int a;

  @Int16()
  int b;

  @Int32()
  int c;

  @Int64()
  int d;

  @Uint8()
  int e;

  @Uint16()
  int f;

  @Uint32()
  int g;

  @Uint64()
  int h;

  @IntPtr()
  int i;

  @Double()
  double j;

  @Float()
  double k;

  Pointer<VeryLargeStruct> parent;

  @IntPtr()
  int numChildren;

  Pointer<VeryLargeStruct> children;

  @Int8()
  int smallLastField;
}
