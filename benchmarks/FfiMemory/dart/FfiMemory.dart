// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(37581): Generate this file.

// Micro-benchmarks for ffi memory stores and loads.
//
// These micro benchmarks track the speed of reading and writing C memory from
// Dart with a specific marshalling and unmarshalling of data.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

//
// Pointer store.
//

void doStoreInt8(Pointer<Int8> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1;
  }
}

void doStoreUint8(Pointer<Uint8> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1;
  }
}

void doStoreInt16(Pointer<Int16> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1;
  }
}

void doStoreUint16(Pointer<Uint16> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1;
  }
}

void doStoreInt32(Pointer<Int32> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1;
  }
}

void doStoreUint32(Pointer<Uint32> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1;
  }
}

void doStoreInt64(Pointer<Int64> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1;
  }
}

void doStoreUint64(Pointer<Uint64> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1;
  }
}

void doStoreFloat(Pointer<Float> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1.0;
  }
}

void doStoreDouble(Pointer<Double> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 1.0;
  }
}

void doStorePointer(
    Pointer<Pointer<Int8>> pointer, int length, Pointer<Int8> data) {
  for (int i = 0; i < length; i++) {
    pointer[i] = data;
  }
}

void doStoreInt64Mint(Pointer<Int64> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i] = 0x7FFFFFFFFFFFFFFF;
  }
}

//
// Pointer load.
//

int doLoadInt8(Pointer<Int8> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

int doLoadUint8(Pointer<Uint8> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

int doLoadInt16(Pointer<Int16> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

int doLoadUint16(Pointer<Uint16> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

int doLoadInt32(Pointer<Int32> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

int doLoadUint32(Pointer<Uint32> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

int doLoadInt64(Pointer<Int64> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

int doLoadUint64(Pointer<Uint64> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

double doLoadFloat(Pointer<Float> pointer, int length) {
  double x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

double doLoadDouble(Pointer<Double> pointer, int length) {
  double x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

// Aggregates pointers through aggregrating their addresses.
int doLoadPointer(Pointer<Pointer<Int8>> pointer, int length) {
  Pointer<Int8> x;
  int address_xor = 0;
  for (int i = 0; i < length; i++) {
    x = pointer[i];
    address_xor ^= x.address;
  }
  return address_xor;
}

int doLoadInt64Mint(Pointer<Int64> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i];
  }
  return x;
}

//
// Benchmark fixtures.
//

// Number of repeats: 1000
//  * CPU: Intel(R) Xeon(R) Gold 6154
//    * Architecture: x64
//      * 48000 - 125000 us (without optimizations)
//      * 14 - ??? us (expected with optimizations, on par with typed data)
const N = 1000;

class PointerInt8 extends BenchmarkBase {
  Pointer<Int8> pointer = nullptr;
  PointerInt8() : super('FfiMemory.PointerInt8');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreInt8(pointer, N);
    final int x = doLoadInt8(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerUint8 extends BenchmarkBase {
  Pointer<Uint8> pointer = nullptr;
  PointerUint8() : super('FfiMemory.PointerUint8');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreUint8(pointer, N);
    final int x = doLoadUint8(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerInt16 extends BenchmarkBase {
  Pointer<Int16> pointer = nullptr;
  PointerInt16() : super('FfiMemory.PointerInt16');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreInt16(pointer, N);
    final int x = doLoadInt16(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerUint16 extends BenchmarkBase {
  Pointer<Uint16> pointer = nullptr;
  PointerUint16() : super('FfiMemory.PointerUint16');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreUint16(pointer, N);
    final int x = doLoadUint16(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerInt32 extends BenchmarkBase {
  Pointer<Int32> pointer = nullptr;
  PointerInt32() : super('FfiMemory.PointerInt32');

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

class PointerUint32 extends BenchmarkBase {
  Pointer<Uint32> pointer = nullptr;
  PointerUint32() : super('FfiMemory.PointerUint32');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreUint32(pointer, N);
    final int x = doLoadUint32(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerInt64 extends BenchmarkBase {
  Pointer<Int64> pointer = nullptr;
  PointerInt64() : super('FfiMemory.PointerInt64');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreInt64(pointer, N);
    final int x = doLoadInt64(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerUint64 extends BenchmarkBase {
  Pointer<Uint64> pointer = nullptr;
  PointerUint64() : super('FfiMemory.PointerUint64');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreUint64(pointer, N);
    final int x = doLoadUint64(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerFloat extends BenchmarkBase {
  Pointer<Float> pointer = nullptr;
  PointerFloat() : super('FfiMemory.PointerFloat');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreFloat(pointer, N);
    final double x = doLoadFloat(pointer, N);
    if (0.99 * N > x || x > 1.01 * N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerDouble extends BenchmarkBase {
  Pointer<Double> pointer = nullptr;
  PointerDouble() : super('FfiMemory.PointerDouble');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreDouble(pointer, N);
    final double x = doLoadDouble(pointer, N);
    if (0.99 * N > x || x > 1.01 * N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerPointer extends BenchmarkBase {
  Pointer<Pointer<Int8>> pointer = nullptr;
  Pointer<Int8> data = nullptr;
  PointerPointer() : super('FfiMemory.PointerPointer');

  @override
  void setup() {
    pointer = allocate(count: N);
    data = allocate();
  }

  @override
  void teardown() {
    free(pointer);
    free(data);
  }

  @override
  void run() {
    doStorePointer(pointer, N, data);
    final int x = doLoadPointer(pointer, N);
    if (x != 0 || x == data.address) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class PointerInt64Mint extends BenchmarkBase {
  Pointer<Int64> pointer = nullptr;
  PointerInt64Mint() : super('FfiMemory.PointerInt64Mint');

  @override
  void setup() => pointer = allocate(count: N);
  @override
  void teardown() => free(pointer);

  @override
  void run() {
    doStoreInt64Mint(pointer, N);
    final int x = doLoadInt64Mint(pointer, N);
    // Using overflow semantics in aggregation.
    if (x != -N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

//
// Main driver.
//

void main() {
  final benchmarks = [
    () => PointerInt8(),
    () => PointerUint8(),
    () => PointerInt16(),
    () => PointerUint16(),
    () => PointerInt32(),
    () => PointerUint32(),
    () => PointerInt64(),
    () => PointerInt64Mint(),
    () => PointerUint64(),
    () => PointerFloat(),
    () => PointerDouble(),
    () => PointerPointer(),
  ];
  for (final benchmark in benchmarks) {
    benchmark().report();
  }
}
