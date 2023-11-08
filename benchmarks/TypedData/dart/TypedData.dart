// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Micro-benchmarks for typed data setters and getters.
//

import 'dart:typed_data';
import 'package:benchmark_harness/benchmark_harness.dart';

//
// Typed constant setters.
//

void doSetInt8(Int8List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetUint8(Uint8List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetUint8Clamped(Uint8ClampedList list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetInt16(Int16List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetUint16(Uint16List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetInt32(Int32List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetUint32(Uint32List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetInt64(Int64List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetUint64(Uint64List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

void doSetFloat32(Float32List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1.0;
  }
}

void doSetFloat64(Float64List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1.0;
  }
}

//
// Typed variable setters.
//

void doSetInt8Var(Int8List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetUint8Var(Uint8List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetUint8ClampedVar(Uint8ClampedList list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetInt16Var(Int16List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetUint16Var(Uint16List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetInt32Var(Int32List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetUint32Var(Uint32List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetInt64Var(Int64List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetUint64Var(Uint64List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }
}

void doSetFloat32Var(Float32List list) {
  double x = 0.0;
  for (int i = 0; i < list.length; i++) {
    list[i] = x++;
  }
}

void doSetFloat64Var(Float64List list) {
  double x = 0.0;
  for (int i = 0; i < list.length; i++) {
    list[i] = x++;
  }
}

//
// Typed getters.
//

int doGetInt8(Int8List list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

int doGetUint8(Uint8List list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

int doGetUint8Clamped(Uint8ClampedList list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

int doGetInt16(Int16List list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

int doGetUint16(Uint16List list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

int doGetInt32(Int32List list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

int doGetUint32(Uint32List list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

int doGetInt64(Int64List list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

int doGetUint64(Uint64List list) {
  int x = 0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

double doGetFloat32(Float32List list) {
  double x = 0.0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

double doGetFloat64(Float64List list) {
  double x = 0.0;
  for (int i = 0; i < list.length; i++) {
    x += list[i];
  }
  return x;
}

//
// Benchmark fixtures.
//

const N = 1000;

class Int8ListBench extends BenchmarkBase {
  var list = Int8List(N);
  Int8ListBench() : super('TypedData.Int8ListBench');
  @override
  void run() {
    doSetInt8(list);
    final int x = doGetInt8(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint8ListBench extends BenchmarkBase {
  var list = Uint8List(N);
  Uint8ListBench() : super('TypedData.Uint8ListBench');
  @override
  void run() {
    doSetUint8(list);
    final int x = doGetUint8(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint8ClampedListBench extends BenchmarkBase {
  var list = Uint8ClampedList(N);
  Uint8ClampedListBench() : super('TypedData.Uint8ClampedListBench');
  @override
  void run() {
    doSetUint8Clamped(list);
    final int x = doGetUint8Clamped(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int16ListBench extends BenchmarkBase {
  var list = Int16List(N);
  Int16ListBench() : super('TypedData.Int16ListBench');
  @override
  void run() {
    doSetInt16(list);
    final int x = doGetInt16(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint16ListBench extends BenchmarkBase {
  var list = Uint16List(N);
  Uint16ListBench() : super('TypedData.Uint16ListBench');
  @override
  void run() {
    doSetUint16(list);
    final int x = doGetUint16(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int32ListBench extends BenchmarkBase {
  var list = Int32List(N);
  Int32ListBench() : super('TypedData.Int32ListBench');
  @override
  void run() {
    doSetInt32(list);
    final int x = doGetInt32(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint32ListBench extends BenchmarkBase {
  var list = Uint32List(N);
  Uint32ListBench() : super('TypedData.Uint32ListBench');
  @override
  void run() {
    doSetUint32(list);
    final int x = doGetUint32(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int64ListBench extends BenchmarkBase {
  var list = Int64List(N);
  Int64ListBench() : super('TypedData.Int64ListBench');
  @override
  void run() {
    doSetInt64(list);
    final int x = doGetInt64(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint64ListBench extends BenchmarkBase {
  var list = Uint64List(N);
  Uint64ListBench() : super('TypedData.Uint64ListBench');
  @override
  void run() {
    doSetUint64(list);
    final int x = doGetUint64(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Float32ListBench extends BenchmarkBase {
  var list = Float32List(N);
  Float32ListBench() : super('TypedData.Float32ListBench');
  @override
  void run() {
    doSetFloat32(list);
    final double x = doGetFloat32(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Float64ListBench extends BenchmarkBase {
  var list = Float64List(N);
  Float64ListBench() : super('TypedData.Float64ListBench');
  @override
  void run() {
    doSetFloat64(list);
    final double x = doGetFloat64(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int8ListViewBench extends BenchmarkBase {
  var list = Int8List.view(Int8List(N).buffer);
  Int8ListViewBench() : super('TypedData.Int8ListViewBench');
  @override
  void run() {
    doSetInt8(list);
    final int x = doGetInt8(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint8ListViewBench extends BenchmarkBase {
  var list = Uint8List.view(Uint8List(N).buffer);
  Uint8ListViewBench() : super('TypedData.Uint8ListViewBench');
  @override
  void run() {
    doSetUint8(list);
    final int x = doGetUint8(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint8ClampedListViewBench extends BenchmarkBase {
  var list = Uint8ClampedList.view(Uint8ClampedList(N).buffer);
  Uint8ClampedListViewBench() : super('TypedData.Uint8ClampedListViewBench');
  @override
  void run() {
    doSetUint8Clamped(list);
    final int x = doGetUint8Clamped(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int16ListViewBench extends BenchmarkBase {
  var list = Int16List.view(Int16List(N).buffer);
  Int16ListViewBench() : super('TypedData.Int16ListViewBench');
  @override
  void run() {
    doSetInt16(list);
    final int x = doGetInt16(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint16ListViewBench extends BenchmarkBase {
  var list = Uint16List.view(Uint16List(N).buffer);
  Uint16ListViewBench() : super('TypedData.Uint16ListViewBench');
  @override
  void run() {
    doSetUint16(list);
    final int x = doGetUint16(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int32ListViewBench extends BenchmarkBase {
  var list = Int32List.view(Int32List(N).buffer);
  Int32ListViewBench() : super('TypedData.Int32ListViewBench');
  @override
  void run() {
    doSetInt32(list);
    final int x = doGetInt32(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint32ListViewBench extends BenchmarkBase {
  var list = Uint32List.view(Uint32List(N).buffer);
  Uint32ListViewBench() : super('TypedData.Uint32ListViewBench');
  @override
  void run() {
    doSetUint32(list);
    final int x = doGetUint32(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int64ListViewBench extends BenchmarkBase {
  var list = Int64List.view(Int64List(N).buffer);
  Int64ListViewBench() : super('TypedData.Int64ListViewBench');
  @override
  void run() {
    doSetInt64(list);
    final int x = doGetInt64(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint64ListViewBench extends BenchmarkBase {
  var list = Uint64List.view(Uint64List(N).buffer);
  Uint64ListViewBench() : super('TypedData.Uint64ListViewBench');
  @override
  void run() {
    doSetUint64(list);
    final int x = doGetUint64(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Float32ListViewBench extends BenchmarkBase {
  var list = Float32List.view(Float32List(N).buffer);
  Float32ListViewBench() : super('TypedData.Float32ListViewBench');
  @override
  void run() {
    doSetFloat32(list);
    final double x = doGetFloat32(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Float64ListViewBench extends BenchmarkBase {
  var list = Float64List.view(Float64List(N).buffer);
  Float64ListViewBench() : super('TypedData.Float64ListViewBench');
  @override
  void run() {
    doSetFloat64(list);
    final double x = doGetFloat64(list);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int8ListVarBench extends BenchmarkBase {
  var list = Int8List(N);
  Int8ListVarBench() : super('TypedData.Int8ListVarBench');
  @override
  void run() {
    doSetInt8Var(list);
    final int x = doGetInt8(list);
    if (x != -212) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint8ListVarBench extends BenchmarkBase {
  var list = Uint8List(N);
  Uint8ListVarBench() : super('TypedData.Uint8ListVarBench');
  @override
  void run() {
    doSetUint8Var(list);
    final int x = doGetUint8(list);
    if (x != 124716) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint8ClampedListVarBench extends BenchmarkBase {
  var list = Uint8ClampedList(N);
  Uint8ClampedListVarBench() : super('TypedData.Uint8ClampedListVarBench');
  @override
  void run() {
    doSetUint8ClampedVar(list);
    final int x = doGetUint8Clamped(list);
    if (x != 222360) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int16ListVarBench extends BenchmarkBase {
  var list = Int16List(N);
  Int16ListVarBench() : super('TypedData.Int16ListVarBench');
  @override
  void run() {
    doSetInt16Var(list);
    final int x = doGetInt16(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint16ListVarBench extends BenchmarkBase {
  var list = Uint16List(N);
  Uint16ListVarBench() : super('TypedData.Uint16ListVarBench');
  @override
  void run() {
    doSetUint16Var(list);
    final int x = doGetUint16(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int32ListVarBench extends BenchmarkBase {
  var list = Int32List(N);
  Int32ListVarBench() : super('TypedData.Int32ListVarBench');
  @override
  void run() {
    doSetInt32Var(list);
    final int x = doGetInt32(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint32ListVarBench extends BenchmarkBase {
  var list = Uint32List(N);
  Uint32ListVarBench() : super('TypedData.Uint32ListVarBench');
  @override
  void run() {
    doSetUint32Var(list);
    final int x = doGetUint32(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int64ListVarBench extends BenchmarkBase {
  var list = Int64List(N);
  Int64ListVarBench() : super('TypedData.Int64ListVarBench');
  @override
  void run() {
    doSetInt64Var(list);
    final int x = doGetInt64(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint64ListVarBench extends BenchmarkBase {
  var list = Uint64List(N);
  Uint64ListVarBench() : super('TypedData.Uint64ListVarBench');
  @override
  void run() {
    doSetUint64Var(list);
    final int x = doGetUint64(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Float32ListVarBench extends BenchmarkBase {
  var list = Float32List(N);
  Float32ListVarBench() : super('TypedData.Float32ListVarBench');
  @override
  void run() {
    doSetFloat32Var(list);
    final double x = doGetFloat32(list);
    if (x != 499500.0) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Float64ListVarBench extends BenchmarkBase {
  var list = Float64List(N);
  Float64ListVarBench() : super('TypedData.Float64ListVarBench');
  @override
  void run() {
    doSetFloat64Var(list);
    final double x = doGetFloat64(list);
    if (x != 499500.0) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int8ListViewVarBench extends BenchmarkBase {
  var list = Int8List.view(Int8List(N).buffer);
  Int8ListViewVarBench() : super('TypedData.Int8ListViewVarBench');
  @override
  void run() {
    doSetInt8Var(list);
    final int x = doGetInt8(list);
    if (x != -212) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint8ListViewVarBench extends BenchmarkBase {
  var list = Uint8List.view(Uint8List(N).buffer);
  Uint8ListViewVarBench() : super('TypedData.Uint8ListViewVarBench');
  @override
  void run() {
    doSetUint8Var(list);
    final int x = doGetUint8(list);
    if (x != 124716) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint8ClampedListViewVarBench extends BenchmarkBase {
  var list = Uint8ClampedList.view(Uint8ClampedList(N).buffer);
  Uint8ClampedListViewVarBench()
      : super('TypedData.Uint8ClampedListViewVarBench');
  @override
  void run() {
    doSetUint8ClampedVar(list);
    final int x = doGetUint8Clamped(list);
    if (x != 222360) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int16ListViewVarBench extends BenchmarkBase {
  var list = Int16List.view(Int16List(N).buffer);
  Int16ListViewVarBench() : super('TypedData.Int16ListViewVarBench');
  @override
  void run() {
    doSetInt16Var(list);
    final int x = doGetInt16(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint16ListViewVarBench extends BenchmarkBase {
  var list = Uint16List.view(Uint16List(N).buffer);
  Uint16ListViewVarBench() : super('TypedData.Uint16ListViewVarBench');
  @override
  void run() {
    doSetUint16Var(list);
    final int x = doGetUint16(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int32ListViewVarBench extends BenchmarkBase {
  var list = Int32List.view(Int32List(N).buffer);
  Int32ListViewVarBench() : super('TypedData.Int32ListViewVarBench');
  @override
  void run() {
    doSetInt32Var(list);
    final int x = doGetInt32(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint32ListViewVarBench extends BenchmarkBase {
  var list = Uint32List.view(Uint32List(N).buffer);
  Uint32ListViewVarBench() : super('TypedData.Uint32ListViewVarBench');
  @override
  void run() {
    doSetUint32Var(list);
    final int x = doGetUint32(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Int64ListViewVarBench extends BenchmarkBase {
  var list = Int64List.view(Int64List(N).buffer);
  Int64ListViewVarBench() : super('TypedData.Int64ListViewVarBench');
  @override
  void run() {
    doSetInt64Var(list);
    final int x = doGetInt64(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Uint64ListViewVarBench extends BenchmarkBase {
  var list = Uint64List.view(Uint64List(N).buffer);
  Uint64ListViewVarBench() : super('TypedData.Uint64ListViewVarBench');
  @override
  void run() {
    doSetUint64Var(list);
    final int x = doGetUint64(list);
    if (x != 499500) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Float32ListViewVarBench extends BenchmarkBase {
  var list = Float32List.view(Float32List(N).buffer);
  Float32ListViewVarBench() : super('TypedData.Float32ListViewVarBench');
  @override
  void run() {
    doSetFloat32Var(list);
    final double x = doGetFloat32(list);
    if (x != 499500.0) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

class Float64ListViewVarBench extends BenchmarkBase {
  var list = Float64List.view(Float64List(N).buffer);
  Float64ListViewVarBench() : super('TypedData.Float64ListViewVarBench');
  @override
  void run() {
    doSetFloat64Var(list);
    final double x = doGetFloat64(list);
    if (x != 499500.0) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

//
// Main driver.
//

void main() {
  final microBenchmarks = [
    () => Int8ListBench(),
    () => Uint8ListBench(),
    () => Uint8ClampedListBench(),
    () => Int16ListBench(),
    () => Uint16ListBench(),
    () => Int32ListBench(),
    () => Uint32ListBench(),
    () => Int64ListBench(),
    () => Uint64ListBench(),
    () => Float32ListBench(),
    () => Float64ListBench(),
    () => Int8ListViewBench(),
    () => Uint8ListViewBench(),
    () => Uint8ClampedListViewBench(),
    () => Int16ListViewBench(),
    () => Uint16ListViewBench(),
    () => Int32ListViewBench(),
    () => Uint32ListViewBench(),
    () => Int64ListViewBench(),
    () => Uint64ListViewBench(),
    () => Float32ListViewBench(),
    () => Float64ListViewBench(),
    () => Int8ListVarBench(),
    () => Uint8ListVarBench(),
    () => Uint8ClampedListVarBench(),
    () => Int16ListVarBench(),
    () => Uint16ListVarBench(),
    () => Int32ListVarBench(),
    () => Uint32ListVarBench(),
    () => Int64ListVarBench(),
    () => Uint64ListVarBench(),
    () => Float32ListVarBench(),
    () => Float64ListVarBench(),
    () => Int8ListViewVarBench(),
    () => Uint8ListViewVarBench(),
    () => Uint8ClampedListViewVarBench(),
    () => Int16ListViewVarBench(),
    () => Uint16ListViewVarBench(),
    () => Int32ListViewVarBench(),
    () => Uint32ListViewVarBench(),
    () => Int64ListViewVarBench(),
    () => Uint64ListViewVarBench(),
    () => Float32ListViewVarBench(),
    () => Float64ListViewVarBench(),
  ];
  for (var mbm in microBenchmarks) {
    mbm().report();
  }
}
