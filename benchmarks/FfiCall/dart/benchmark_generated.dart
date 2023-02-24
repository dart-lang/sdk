// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, run the following script:
//
// > dart benchmarks/FfiCall/generate_benchmarks.dart

import 'dart:ffi';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ffi/ffi.dart';

import 'FfiCall.dart';

typedef Function1int = int Function(int);
typedef Function2int = int Function(int, int);
typedef Function4int = int Function(int, int, int, int);
typedef Function10int = int Function(
    int, int, int, int, int, int, int, int, int, int);
typedef Function20int = int Function(int, int, int, int, int, int, int, int,
    int, int, int, int, int, int, int, int, int, int, int, int);
typedef Function1double = double Function(double);
typedef Function2double = double Function(double, double);
typedef Function4double = double Function(double, double, double, double);
typedef Function10double = double Function(double, double, double, double,
    double, double, double, double, double, double);
typedef Function20double = double Function(
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double);
typedef Function1PointerUint8 = Pointer<Uint8> Function(Pointer<Uint8>);
typedef Function2PointerUint8 = Pointer<Uint8> Function(
    Pointer<Uint8>, Pointer<Uint8>);
typedef Function4PointerUint8 = Pointer<Uint8> Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>);
typedef Function10PointerUint8 = Pointer<Uint8> Function(
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>);
typedef Function20PointerUint8 = Pointer<Uint8> Function(
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>);
typedef Function1Object = Object Function(Object);
typedef Function2Object = Object Function(Object, Object);
typedef Function4Object = Object Function(Object, Object, Object, Object);
typedef Function10Object = Object Function(Object, Object, Object, Object,
    Object, Object, Object, Object, Object, Object);
typedef Function20Object = Object Function(
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object);
typedef NativeFunction1Int8 = Int8 Function(Int8);
typedef NativeFunction2Int8 = Int8 Function(Int8, Int8);
typedef NativeFunction4Int8 = Int8 Function(Int8, Int8, Int8, Int8);
typedef NativeFunction10Int8 = Int8 Function(
    Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8);
typedef NativeFunction20Int8 = Int8 Function(
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8,
    Int8);
typedef NativeFunction1Int16 = Int16 Function(Int16);
typedef NativeFunction2Int16 = Int16 Function(Int16, Int16);
typedef NativeFunction4Int16 = Int16 Function(Int16, Int16, Int16, Int16);
typedef NativeFunction10Int16 = Int16 Function(
    Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16);
typedef NativeFunction20Int16 = Int16 Function(
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16,
    Int16);
typedef NativeFunction1Int32 = Int32 Function(Int32);
typedef NativeFunction2Int32 = Int32 Function(Int32, Int32);
typedef NativeFunction4Int32 = Int32 Function(Int32, Int32, Int32, Int32);
typedef NativeFunction10Int32 = Int32 Function(
    Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32);
typedef NativeFunction20Int32 = Int32 Function(
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32);
typedef NativeFunction1Int64 = Int64 Function(Int64);
typedef NativeFunction2Int64 = Int64 Function(Int64, Int64);
typedef NativeFunction4Int64 = Int64 Function(Int64, Int64, Int64, Int64);
typedef NativeFunction10Int64 = Int64 Function(
    Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64);
typedef NativeFunction20Int64 = Int64 Function(
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64,
    Int64);
typedef NativeFunction1Uint8 = Uint8 Function(Uint8);
typedef NativeFunction2Uint8 = Uint8 Function(Uint8, Uint8);
typedef NativeFunction4Uint8 = Uint8 Function(Uint8, Uint8, Uint8, Uint8);
typedef NativeFunction10Uint8 = Uint8 Function(
    Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8);
typedef NativeFunction20Uint8 = Uint8 Function(
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8,
    Uint8);
typedef NativeFunction1Uint16 = Uint16 Function(Uint16);
typedef NativeFunction2Uint16 = Uint16 Function(Uint16, Uint16);
typedef NativeFunction4Uint16 = Uint16 Function(Uint16, Uint16, Uint16, Uint16);
typedef NativeFunction10Uint16 = Uint16 Function(Uint16, Uint16, Uint16, Uint16,
    Uint16, Uint16, Uint16, Uint16, Uint16, Uint16);
typedef NativeFunction20Uint16 = Uint16 Function(
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16,
    Uint16);
typedef NativeFunction1Uint32 = Uint32 Function(Uint32);
typedef NativeFunction2Uint32 = Uint32 Function(Uint32, Uint32);
typedef NativeFunction4Uint32 = Uint32 Function(Uint32, Uint32, Uint32, Uint32);
typedef NativeFunction10Uint32 = Uint32 Function(Uint32, Uint32, Uint32, Uint32,
    Uint32, Uint32, Uint32, Uint32, Uint32, Uint32);
typedef NativeFunction20Uint32 = Uint32 Function(
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32,
    Uint32);
typedef NativeFunction1Uint64 = Uint64 Function(Uint64);
typedef NativeFunction2Uint64 = Uint64 Function(Uint64, Uint64);
typedef NativeFunction4Uint64 = Uint64 Function(Uint64, Uint64, Uint64, Uint64);
typedef NativeFunction10Uint64 = Uint64 Function(Uint64, Uint64, Uint64, Uint64,
    Uint64, Uint64, Uint64, Uint64, Uint64, Uint64);
typedef NativeFunction20Uint64 = Uint64 Function(
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64,
    Uint64);
typedef NativeFunction1Float = Float Function(Float);
typedef NativeFunction2Float = Float Function(Float, Float);
typedef NativeFunction4Float = Float Function(Float, Float, Float, Float);
typedef NativeFunction10Float = Float Function(
    Float, Float, Float, Float, Float, Float, Float, Float, Float, Float);
typedef NativeFunction20Float = Float Function(
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float);
typedef NativeFunction1Double = Double Function(Double);
typedef NativeFunction2Double = Double Function(Double, Double);
typedef NativeFunction4Double = Double Function(Double, Double, Double, Double);
typedef NativeFunction10Double = Double Function(Double, Double, Double, Double,
    Double, Double, Double, Double, Double, Double);
typedef NativeFunction20Double = Double Function(
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double);
typedef NativeFunction1PointerUint8 = Pointer<Uint8> Function(Pointer<Uint8>);
typedef NativeFunction2PointerUint8 = Pointer<Uint8> Function(
    Pointer<Uint8>, Pointer<Uint8>);
typedef NativeFunction4PointerUint8 = Pointer<Uint8> Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>);
typedef NativeFunction10PointerUint8 = Pointer<Uint8> Function(
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>);
typedef NativeFunction20PointerUint8 = Pointer<Uint8> Function(
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>,
    Pointer<Uint8>);
typedef NativeFunction1Handle = Handle Function(Handle);
typedef NativeFunction2Handle = Handle Function(Handle, Handle);
typedef NativeFunction4Handle = Handle Function(Handle, Handle, Handle, Handle);
typedef NativeFunction10Handle = Handle Function(Handle, Handle, Handle, Handle,
    Handle, Handle, Handle, Handle, Handle, Handle);
typedef NativeFunction20Handle = Handle Function(
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle);

class Int8x01 extends FfiBenchmarkBase {
  final Function1int f;

  Int8x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Int8,
                Function1int>('Function1Int8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Int8,
                Function1int>('Function1Int8', isLeaf: false),
        super('FfiCall.Int8x01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

class Int16x01 extends FfiBenchmarkBase {
  final Function1int f;

  Int16x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Int16,
                Function1int>('Function1Int16', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Int16,
                Function1int>('Function1Int16', isLeaf: false),
        super('FfiCall.Int16x01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

class Int32x01 extends FfiBenchmarkBase {
  final Function1int f;

  Int32x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Int32,
                Function1int>('Function1Int32', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Int32,
                Function1int>('Function1Int32', isLeaf: false),
        super('FfiCall.Int32x01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i);
    }
    expectEquals(x, N * (N - 1) / 2 + N * 42);
  }
}

class Int32x02 extends FfiBenchmarkBase {
  final Function2int f;

  Int32x02({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction2Int32,
                Function2int>('Function2Int32', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction2Int32,
                Function2int>('Function2Int32', isLeaf: false),
        super('FfiCall.Int32x02', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i);
    }
    expectEquals(x, N * (N - 1) * 2 / 2);
  }
}

class Int32x04 extends FfiBenchmarkBase {
  final Function4int f;

  Int32x04({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction4Int32,
                Function4int>('Function4Int32', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction4Int32,
                Function4int>('Function4Int32', isLeaf: false),
        super('FfiCall.Int32x04', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 4 / 2);
  }
}

class Int32x10 extends FfiBenchmarkBase {
  final Function10int f;

  Int32x10({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction10Int32,
                Function10int>('Function10Int32', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction10Int32,
                Function10int>('Function10Int32', isLeaf: false),
        super('FfiCall.Int32x10', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 10 / 2);
  }
}

class Int32x20 extends FfiBenchmarkBase {
  final Function20int f;

  Int32x20({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction20Int32,
                Function20int>('Function20Int32', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction20Int32,
                Function20int>('Function20Int32', isLeaf: false),
        super('FfiCall.Int32x20', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 20 / 2);
  }
}

class Int64x01 extends FfiBenchmarkBase {
  final Function1int f;

  Int64x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Int64,
                Function1int>('Function1Int64', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Int64,
                Function1int>('Function1Int64', isLeaf: false),
        super('FfiCall.Int64x01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i);
    }
    expectEquals(x, N * (N - 1) / 2 + N * 42);
  }
}

class Int64x02 extends FfiBenchmarkBase {
  final Function2int f;

  Int64x02({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction2Int64,
                Function2int>('Function2Int64', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction2Int64,
                Function2int>('Function2Int64', isLeaf: false),
        super('FfiCall.Int64x02', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i);
    }
    expectEquals(x, N * (N - 1) * 2 / 2);
  }
}

class Int64x04 extends FfiBenchmarkBase {
  final Function4int f;

  Int64x04({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction4Int64,
                Function4int>('Function4Int64', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction4Int64,
                Function4int>('Function4Int64', isLeaf: false),
        super('FfiCall.Int64x04', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 4 / 2);
  }
}

class Int64x10 extends FfiBenchmarkBase {
  final Function10int f;

  Int64x10({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction10Int64,
                Function10int>('Function10Int64', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction10Int64,
                Function10int>('Function10Int64', isLeaf: false),
        super('FfiCall.Int64x10', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 10 / 2);
  }
}

class Int64x20 extends FfiBenchmarkBase {
  final Function20int f;

  Int64x20({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction20Int64,
                Function20int>('Function20Int64', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction20Int64,
                Function20int>('Function20Int64', isLeaf: false),
        super('FfiCall.Int64x20', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 20 / 2);
  }
}

class Uint8x01 extends FfiBenchmarkBase {
  final Function1int f;

  Uint8x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Uint8,
                Function1int>('Function1Uint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Uint8,
                Function1int>('Function1Uint8', isLeaf: false),
        super('FfiCall.Uint8x01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

class Uint16x01 extends FfiBenchmarkBase {
  final Function1int f;

  Uint16x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Uint16,
                Function1int>('Function1Uint16', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Uint16,
                Function1int>('Function1Uint16', isLeaf: false),
        super('FfiCall.Uint16x01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

class Uint32x01 extends FfiBenchmarkBase {
  final Function1int f;

  Uint32x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Uint32,
                Function1int>('Function1Uint32', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Uint32,
                Function1int>('Function1Uint32', isLeaf: false),
        super('FfiCall.Uint32x01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i);
    }
    expectEquals(x, N * (N - 1) / 2 + N * 42);
  }
}

class Uint64x01 extends FfiBenchmarkBase {
  final Function1int f;

  Uint64x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Uint64,
                Function1int>('Function1Uint64', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Uint64,
                Function1int>('Function1Uint64', isLeaf: false),
        super('FfiCall.Uint64x01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i);
    }
    expectEquals(x, N * (N - 1) / 2 + N * 42);
  }
}

class Floatx01 extends FfiBenchmarkBase {
  final Function1double f;

  Floatx01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Float,
                Function1double>('Function1Float', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Float,
                Function1double>('Function1Float', isLeaf: false),
        super('FfiCall.Floatx01', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0);
    }
    final double expected = N + N * 42.0;
    expectApprox(x, expected);
  }
}

class Floatx02 extends FfiBenchmarkBase {
  final Function2double f;

  Floatx02({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction2Float,
                Function2double>('Function2Float', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction2Float,
                Function2double>('Function2Float', isLeaf: false),
        super('FfiCall.Floatx02', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0);
    }
    final double expected = N * 2 * (2 + 1) / 2;
    expectApprox(x, expected);
  }
}

class Floatx04 extends FfiBenchmarkBase {
  final Function4double f;

  Floatx04({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction4Float,
                Function4double>('Function4Float', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction4Float,
                Function4double>('Function4Float', isLeaf: false),
        super('FfiCall.Floatx04', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0, 3.0, 4.0);
    }
    final double expected = N * 4 * (4 + 1) / 2;
    expectApprox(x, expected);
  }
}

class Floatx10 extends FfiBenchmarkBase {
  final Function10double f;

  Floatx10({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction10Float,
                Function10double>('Function10Float', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction10Float,
                Function10double>('Function10Float', isLeaf: false),
        super('FfiCall.Floatx10', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0);
    }
    final double expected = N * 10 * (10 + 1) / 2;
    expectApprox(x, expected);
  }
}

class Floatx20 extends FfiBenchmarkBase {
  final Function20double f;

  Floatx20({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction20Float,
                Function20double>('Function20Float', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction20Float,
                Function20double>('Function20Float', isLeaf: false),
        super('FfiCall.Floatx20', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0,
          13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0);
    }
    final double expected = N * 20 * (20 + 1) / 2;
    expectApprox(x, expected);
  }
}

class Doublex01 extends FfiBenchmarkBase {
  final Function1double f;

  Doublex01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Double,
                Function1double>('Function1Double', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Double,
                Function1double>('Function1Double', isLeaf: false),
        super('FfiCall.Doublex01', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0);
    }
    final double expected = N + N * 42.0;
    expectApprox(x, expected);
  }
}

class Doublex02 extends FfiBenchmarkBase {
  final Function2double f;

  Doublex02({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction2Double,
                Function2double>('Function2Double', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction2Double,
                Function2double>('Function2Double', isLeaf: false),
        super('FfiCall.Doublex02', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0);
    }
    final double expected = N * 2 * (2 + 1) / 2;
    expectApprox(x, expected);
  }
}

class Doublex04 extends FfiBenchmarkBase {
  final Function4double f;

  Doublex04({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction4Double,
                Function4double>('Function4Double', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction4Double,
                Function4double>('Function4Double', isLeaf: false),
        super('FfiCall.Doublex04', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0, 3.0, 4.0);
    }
    final double expected = N * 4 * (4 + 1) / 2;
    expectApprox(x, expected);
  }
}

class Doublex10 extends FfiBenchmarkBase {
  final Function10double f;

  Doublex10({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction10Double,
                Function10double>('Function10Double', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction10Double,
                Function10double>('Function10Double', isLeaf: false),
        super('FfiCall.Doublex10', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0);
    }
    final double expected = N * 10 * (10 + 1) / 2;
    expectApprox(x, expected);
  }
}

class Doublex20 extends FfiBenchmarkBase {
  final Function20double f;

  Doublex20({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction20Double,
                Function20double>('Function20Double', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction20Double,
                Function20double>('Function20Double', isLeaf: false),
        super('FfiCall.Doublex20', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0,
          13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0);
    }
    final double expected = N * 20 * (20 + 1) / 2;
    expectApprox(x, expected);
  }
}

class PointerUint8x01 extends FfiBenchmarkBase {
  final Function1PointerUint8 f;

  PointerUint8x01({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1PointerUint8,
                Function1PointerUint8>('Function1PointerUint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1PointerUint8,
                Function1PointerUint8>('Function1PointerUint8', isLeaf: false),
        super('FfiCall.PointerUint8x01', isLeaf: isLeaf);

  Pointer<Uint8> p1 = nullptr;

  @override
  void setup() {
    p1 = calloc(N + 1);
  }

  @override
  void teardown() {
    calloc.free(p1);
  }

  @override
  void run() {
    Pointer<Uint8> x = p1;
    for (int i = 0; i < N; i++) {
      x = f(
        x,
      );
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

class PointerUint8x02 extends FfiBenchmarkBase {
  final Function2PointerUint8 f;

  PointerUint8x02({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction2PointerUint8,
                Function2PointerUint8>('Function2PointerUint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction2PointerUint8,
                Function2PointerUint8>('Function2PointerUint8', isLeaf: false),
        super('FfiCall.PointerUint8x02', isLeaf: isLeaf);

  Pointer<Uint8> p1 = nullptr;
  Pointer<Uint8> p2 = nullptr;

  @override
  void setup() {
    p1 = calloc(N + 1);
    p2 = p1.elementAt(1);
  }

  @override
  void teardown() {
    calloc.free(p1);
  }

  @override
  void run() {
    Pointer<Uint8> x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

class PointerUint8x04 extends FfiBenchmarkBase {
  final Function4PointerUint8 f;

  PointerUint8x04({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction4PointerUint8,
                Function4PointerUint8>('Function4PointerUint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction4PointerUint8,
                Function4PointerUint8>('Function4PointerUint8', isLeaf: false),
        super('FfiCall.PointerUint8x04', isLeaf: isLeaf);

  Pointer<Uint8> p1 = nullptr;
  Pointer<Uint8> p2 = nullptr;
  Pointer<Uint8> p3 = nullptr;
  Pointer<Uint8> p4 = nullptr;

  @override
  void setup() {
    p1 = calloc(N + 1);
    p2 = p1.elementAt(1);
    p3 = p1.elementAt(2);
    p4 = p1.elementAt(3);
  }

  @override
  void teardown() {
    calloc.free(p1);
  }

  @override
  void run() {
    Pointer<Uint8> x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2, p3, p4);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

class PointerUint8x10 extends FfiBenchmarkBase {
  final Function10PointerUint8 f;

  PointerUint8x10({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction10PointerUint8,
                Function10PointerUint8>('Function10PointerUint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction10PointerUint8,
                    Function10PointerUint8>('Function10PointerUint8',
                isLeaf: false),
        super('FfiCall.PointerUint8x10', isLeaf: isLeaf);

  Pointer<Uint8> p1 = nullptr;
  Pointer<Uint8> p2 = nullptr;
  Pointer<Uint8> p3 = nullptr;
  Pointer<Uint8> p4 = nullptr;
  Pointer<Uint8> p5 = nullptr;
  Pointer<Uint8> p6 = nullptr;
  Pointer<Uint8> p7 = nullptr;
  Pointer<Uint8> p8 = nullptr;
  Pointer<Uint8> p9 = nullptr;
  Pointer<Uint8> p10 = nullptr;

  @override
  void setup() {
    p1 = calloc(N + 1);
    p2 = p1.elementAt(1);
    p3 = p1.elementAt(2);
    p4 = p1.elementAt(3);
    p5 = p1.elementAt(4);
    p6 = p1.elementAt(5);
    p7 = p1.elementAt(6);
    p8 = p1.elementAt(7);
    p9 = p1.elementAt(8);
    p10 = p1.elementAt(9);
  }

  @override
  void teardown() {
    calloc.free(p1);
  }

  @override
  void run() {
    Pointer<Uint8> x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2, p3, p4, p5, p6, p7, p8, p9, p10);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

class PointerUint8x20 extends FfiBenchmarkBase {
  final Function20PointerUint8 f;

  PointerUint8x20({bool isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction20PointerUint8,
                Function20PointerUint8>('Function20PointerUint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction20PointerUint8,
                    Function20PointerUint8>('Function20PointerUint8',
                isLeaf: false),
        super('FfiCall.PointerUint8x20', isLeaf: isLeaf);

  Pointer<Uint8> p1 = nullptr;
  Pointer<Uint8> p2 = nullptr;
  Pointer<Uint8> p3 = nullptr;
  Pointer<Uint8> p4 = nullptr;
  Pointer<Uint8> p5 = nullptr;
  Pointer<Uint8> p6 = nullptr;
  Pointer<Uint8> p7 = nullptr;
  Pointer<Uint8> p8 = nullptr;
  Pointer<Uint8> p9 = nullptr;
  Pointer<Uint8> p10 = nullptr;
  Pointer<Uint8> p11 = nullptr;
  Pointer<Uint8> p12 = nullptr;
  Pointer<Uint8> p13 = nullptr;
  Pointer<Uint8> p14 = nullptr;
  Pointer<Uint8> p15 = nullptr;
  Pointer<Uint8> p16 = nullptr;
  Pointer<Uint8> p17 = nullptr;
  Pointer<Uint8> p18 = nullptr;
  Pointer<Uint8> p19 = nullptr;
  Pointer<Uint8> p20 = nullptr;

  @override
  void setup() {
    p1 = calloc(N + 1);
    p2 = p1.elementAt(1);
    p3 = p1.elementAt(2);
    p4 = p1.elementAt(3);
    p5 = p1.elementAt(4);
    p6 = p1.elementAt(5);
    p7 = p1.elementAt(6);
    p8 = p1.elementAt(7);
    p9 = p1.elementAt(8);
    p10 = p1.elementAt(9);
    p11 = p1.elementAt(10);
    p12 = p1.elementAt(11);
    p13 = p1.elementAt(12);
    p14 = p1.elementAt(13);
    p15 = p1.elementAt(14);
    p16 = p1.elementAt(15);
    p17 = p1.elementAt(16);
    p18 = p1.elementAt(17);
    p19 = p1.elementAt(18);
    p20 = p1.elementAt(19);
  }

  @override
  void teardown() {
    calloc.free(p1);
  }

  @override
  void run() {
    Pointer<Uint8> x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15,
          p16, p17, p18, p19, p20);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

class Handlex01 extends FfiBenchmarkBase {
  final Function1Object f;

  Handlex01()
      : f = ffiTestFunctions.lookupFunction<NativeFunction1Handle,
            Function1Object>('Function1Handle', isLeaf: false),
        super('FfiCall.Handlex01', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);

    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = f(
        x,
      );
    }
    expectIdentical(x, m1);
  }
}

class Handlex02 extends FfiBenchmarkBase {
  final Function2Object f;

  Handlex02()
      : f = ffiTestFunctions.lookupFunction<NativeFunction2Handle,
            Function2Object>('Function2Handle', isLeaf: false),
        super('FfiCall.Handlex02', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);
    final m2 = MyClass(2);
    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = f(x, m2);
    }
    expectIdentical(x, m1);
  }
}

class Handlex04 extends FfiBenchmarkBase {
  final Function4Object f;

  Handlex04()
      : f = ffiTestFunctions.lookupFunction<NativeFunction4Handle,
            Function4Object>('Function4Handle', isLeaf: false),
        super('FfiCall.Handlex04', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);
    final m2 = MyClass(2);
    final m3 = MyClass(3);
    final m4 = MyClass(4);
    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = f(x, m2, m3, m4);
    }
    expectIdentical(x, m1);
  }
}

class Handlex10 extends FfiBenchmarkBase {
  final Function10Object f;

  Handlex10()
      : f = ffiTestFunctions.lookupFunction<NativeFunction10Handle,
            Function10Object>('Function10Handle', isLeaf: false),
        super('FfiCall.Handlex10', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);
    final m2 = MyClass(2);
    final m3 = MyClass(3);
    final m4 = MyClass(4);
    final m5 = MyClass(5);
    final m6 = MyClass(6);
    final m7 = MyClass(7);
    final m8 = MyClass(8);
    final m9 = MyClass(9);
    final m10 = MyClass(10);
    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = f(x, m2, m3, m4, m5, m6, m7, m8, m9, m10);
    }
    expectIdentical(x, m1);
  }
}

class Handlex20 extends FfiBenchmarkBase {
  final Function20Object f;

  Handlex20()
      : f = ffiTestFunctions.lookupFunction<NativeFunction20Handle,
            Function20Object>('Function20Handle', isLeaf: false),
        super('FfiCall.Handlex20', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);
    final m2 = MyClass(2);
    final m3 = MyClass(3);
    final m4 = MyClass(4);
    final m5 = MyClass(5);
    final m6 = MyClass(6);
    final m7 = MyClass(7);
    final m8 = MyClass(8);
    final m9 = MyClass(9);
    final m10 = MyClass(10);
    final m11 = MyClass(11);
    final m12 = MyClass(12);
    final m13 = MyClass(13);
    final m14 = MyClass(14);
    final m15 = MyClass(15);
    final m16 = MyClass(16);
    final m17 = MyClass(17);
    final m18 = MyClass(18);
    final m19 = MyClass(19);
    final m20 = MyClass(20);
    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = f(x, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15,
          m16, m17, m18, m19, m20);
    }
    expectIdentical(x, m1);
  }
}
