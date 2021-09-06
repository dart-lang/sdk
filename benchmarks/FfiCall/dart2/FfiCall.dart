// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(37581): Generate this file.

// These micro benchmarks track the speed of reading and writing C memory from
// Dart with a specific marshalling and unmarshalling of data.

// @dart=2.9

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

import 'dlopen_helper.dart';

// Number of benchmark iterations per function.
const N = 1000;

// The native library that holds all the native functions being called.
DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific('native_functions',
    path: Platform.script.resolve('../native/out/').path);

//
// Native types and their Dart counterparts.
//

typedef NativeFunction1Uint8 = Uint8 Function(Uint8);
typedef NativeFunction1Uint16 = Uint16 Function(Uint16);
typedef NativeFunction1Uint32 = Uint32 Function(Uint32);
typedef NativeFunction1Uint64 = Uint64 Function(Uint64);
typedef NativeFunction1Int8 = Int8 Function(Int8);
typedef NativeFunction1Int16 = Int16 Function(Int16);
typedef NativeFunction1Int32 = Int32 Function(Int32);
typedef NativeFunction1Int64 = Int64 Function(Int64);
typedef Function1int = int Function(int);

typedef NativeFunction2Int32 = Int32 Function(Int32, Int32);
typedef NativeFunction2Int64 = Int64 Function(Int64, Int64);
typedef Function2int = int Function(int, int);

typedef NativeFunction4Int32 = Int32 Function(Int32, Int32, Int32, Int32);
typedef NativeFunction4Int64 = Int64 Function(Int64, Int64, Int64, Int64);
typedef Function4int = int Function(int, int, int, int);

typedef NativeFunction10Int32 = Int32 Function(
    Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32);
typedef NativeFunction10Int64 = Int64 Function(
    Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64);
typedef Function10int = int Function(
    int, int, int, int, int, int, int, int, int, int);

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
typedef Function20int = int Function(int, int, int, int, int, int, int, int,
    int, int, int, int, int, int, int, int, int, int, int, int);

typedef NativeFunction1Float = Float Function(Float);
typedef NativeFunction1Double = Double Function(Double);
typedef Function1double = double Function(double);

typedef NativeFunction2Float = Float Function(Float, Float);
typedef NativeFunction2Double = Double Function(Double, Double);
typedef Function2double = double Function(double, double);

typedef NativeFunction4Float = Float Function(Float, Float, Float, Float);
typedef NativeFunction4Double = Double Function(Double, Double, Double, Double);
typedef Function4double = double Function(double, double, double, double);

typedef NativeFunction10Float = Float Function(
    Float, Float, Float, Float, Float, Float, Float, Float, Float, Float);
typedef NativeFunction10Double = Double Function(Double, Double, Double, Double,
    Double, Double, Double, Double, Double, Double);
typedef Function10double = double Function(double, double, double, double,
    double, double, double, double, double, double);

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

typedef NativeFunction1Handle = Handle Function(Handle);
typedef Function1Object = Object Function(Object);

typedef NativeFunction2Handle = Handle Function(Handle, Handle);
typedef Function2Object = Object Function(Object, Object);

typedef NativeFunction4Handle = Handle Function(Handle, Handle, Handle, Handle);
typedef Function4Object = Object Function(Object, Object, Object, Object);

typedef NativeFunction10Handle = Handle Function(Handle, Handle, Handle, Handle,
    Handle, Handle, Handle, Handle, Handle, Handle);
typedef Function10Object = Object Function(Object, Object, Object, Object,
    Object, Object, Object, Object, Object, Object);

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

//
// Benchmark fixtures.
//

abstract class FfiBenchmarkBase extends BenchmarkBase {
  final bool isLeaf;

  FfiBenchmarkBase(String name, {this.isLeaf: false})
      : super('$name${isLeaf ? 'Leaf' : ''}');

  void expectEquals(actual, expected) {
    if (actual != expected) {
      throw Exception('$name: Unexpected result: $actual, expected $expected');
    }
  }

  void expectApprox(actual, expected) {
    if (0.999 * expected > actual || actual > 1.001 * expected) {
      throw Exception('$name: Unexpected result: $actual, expected $expected');
    }
  }

  void expectIdentical(actual, expected) {
    if (!identical(actual, expected)) {
      throw Exception('$name: Unexpected result: $actual, expected $expected');
    }
  }
}

class Uint8x01 extends FfiBenchmarkBase {
  final Function1int f;

  Uint8x01({isLeaf: false})
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

  Uint16x01({isLeaf: false})
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
    expectEquals(x, N * (17 + 42));
  }
}

class Uint32x01 extends FfiBenchmarkBase {
  final Function1int f;

  Uint32x01({isLeaf: false})
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

  Uint64x01({isLeaf: false})
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

class Int8x01 extends FfiBenchmarkBase {
  final Function1int f;

  Int8x01({isLeaf: false})
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
    expectEquals(x, N * (17 + 42));
  }
}

class Int16x01 extends FfiBenchmarkBase {
  final Function1int f;

  Int16x01({isLeaf: false})
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
    expectEquals(x, N * (17 + 42));
  }
}

class Int32x01 extends FfiBenchmarkBase {
  final Function1int f;

  Int32x01({isLeaf: false})
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

  Int32x02({isLeaf: false})
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

  Int32x04({isLeaf: false})
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

  Int32x10({isLeaf: false})
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

  Int32x20({isLeaf: false})
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

  Int64x01({isLeaf: false})
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

  Int64x02({isLeaf: false})
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

  Int64x04({isLeaf: false})
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

  Int64x10({isLeaf: false})
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

  Int64x20({isLeaf: false})
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

class Int64Mintx01 extends FfiBenchmarkBase {
  final Function1int f;

  Int64Mintx01({isLeaf: false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Int64,
                Function1int>('Function1Int64', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Int64,
                Function1int>('Function1Int64', isLeaf: false),
        super('FfiCall.Int64Mintx01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0x7FFFFFFF00000000;
    for (int i = 0; i < N; i++) {
      x = f(x);
    }
    expectEquals(x, 0x7FFFFFFF00000000 + N * 42);
  }
}

class Floatx01 extends FfiBenchmarkBase {
  final Function1double f;

  Floatx01({isLeaf: false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Float,
                Function1double>('Function1Float', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Float,
                Function1double>('Function1Float', isLeaf: false),
        super('FfiCall.Floatx01', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0.0;
    for (int i = 0; i < N; i++) {
      x += f(17.0);
    }
    expectApprox(x, N * (17.0 + 42.0));
  }
}

class Floatx02 extends FfiBenchmarkBase {
  final Function2double f;

  Floatx02({isLeaf: false})
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
    expectApprox(x, N * (1.0 + 2.0));
  }
}

class Floatx04 extends FfiBenchmarkBase {
  final Function4double f;

  Floatx04({isLeaf: false})
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
    final double expected = N * (1.0 + 2.0 + 3.0 + 4.0);
    expectApprox(x, expected);
  }
}

class Floatx10 extends FfiBenchmarkBase {
  final Function10double f;

  Floatx10({isLeaf: false})
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
    final double expected =
        N * (1.0 + 2.0 + 3.0 + 4.0 + 5.0 + 6.0 + 7.0 + 8.0 + 9.0 + 10.0);
    expectApprox(x, expected);
  }
}

class Floatx20 extends FfiBenchmarkBase {
  final Function20double f;

  Floatx20({isLeaf: false})
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
    final double expected = N *
        (1.0 +
            2.0 +
            3.0 +
            4.0 +
            5.0 +
            6.0 +
            7.0 +
            8.0 +
            9.0 +
            10.0 +
            11.0 +
            12.0 +
            13.0 +
            14.0 +
            15.0 +
            16.0 +
            17.0 +
            18.0 +
            19.0 +
            20.0);
    expectApprox(x, expected);
  }
}

class Doublex01 extends FfiBenchmarkBase {
  final Function1double f;

  Doublex01({isLeaf: false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Double,
                Function1double>('Function1Double', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Double,
                Function1double>('Function1Double', isLeaf: false),
        super('FfiCall.Doublex01', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0.0;
    for (int i = 0; i < N; i++) {
      x += f(17.0);
    }
    final double expected = N * (17.0 + 42.0);
    expectApprox(x, expected);
  }
}

class Doublex02 extends FfiBenchmarkBase {
  final Function2double f;

  Doublex02({isLeaf: false})
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
    final double expected = N * (1.0 + 2.0);
    expectApprox(x, expected);
  }
}

class Doublex04 extends FfiBenchmarkBase {
  final Function4double f;

  Doublex04({isLeaf: false})
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
    final double expected = N * (1.0 + 2.0 + 3.0 + 4.0);
    expectApprox(x, expected);
  }
}

class Doublex10 extends FfiBenchmarkBase {
  final Function10double f;

  Doublex10({isLeaf: false})
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
    final double expected =
        N * (1.0 + 2.0 + 3.0 + 4.0 + 5.0 + 6.0 + 7.0 + 8.0 + 9.0 + 10.0);
    expectApprox(x, expected);
  }
}

class Doublex20 extends FfiBenchmarkBase {
  final Function20double f;

  Doublex20({isLeaf: false})
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
    final double expected = N *
        (1.0 +
            2.0 +
            3.0 +
            4.0 +
            5.0 +
            6.0 +
            7.0 +
            8.0 +
            9.0 +
            10.0 +
            11.0 +
            12.0 +
            13.0 +
            14.0 +
            15.0 +
            16.0 +
            17.0 +
            18.0 +
            19.0 +
            20.0);
    expectApprox(x, expected);
  }
}

class PointerUint8x01 extends FfiBenchmarkBase {
  final Function1PointerUint8 f;

  PointerUint8x01({isLeaf: false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<Function1PointerUint8,
                Function1PointerUint8>('Function1PointerUint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<Function1PointerUint8,
                Function1PointerUint8>('Function1PointerUint8', isLeaf: false),
        super('FfiCall.PointerUint8x01', isLeaf: isLeaf);

  Pointer<Uint8> p1;
  @override
  void setup() => p1 = calloc(N + 1);
  @override
  void teardown() => calloc.free(p1);

  @override
  void run() {
    Pointer<Uint8> x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x);
    }
    expectApprox(x.address, p1.address + N);
  }
}

class PointerUint8x02 extends FfiBenchmarkBase {
  final Function2PointerUint8 f;

  PointerUint8x02({isLeaf: false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<Function2PointerUint8,
                Function2PointerUint8>('Function2PointerUint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<Function2PointerUint8,
                Function2PointerUint8>('Function2PointerUint8', isLeaf: false),
        super('FfiCall.PointerUint8x02', isLeaf: isLeaf);

  Pointer<Uint8> p1, p2;

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

  PointerUint8x04({isLeaf: false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<Function4PointerUint8,
                Function4PointerUint8>('Function4PointerUint8', isLeaf: true)
            : ffiTestFunctions.lookupFunction<Function4PointerUint8,
                Function4PointerUint8>('Function4PointerUint8', isLeaf: false),
        super('FfiCall.PointerUint8x04', isLeaf: isLeaf);

  Pointer<Uint8> p1, p2, p3, p4;

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

  PointerUint8x10({isLeaf: false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<Function10PointerUint8,
                Function10PointerUint8>('Function10PointerUint8', isLeaf: true)
            : ffiTestFunctions
                .lookupFunction<Function10PointerUint8, Function10PointerUint8>(
                    'Function10PointerUint8',
                    isLeaf: false),
        super('FfiCall.PointerUint8x10', isLeaf: isLeaf);

  Pointer<Uint8> p1, p2, p3, p4, p5, p6, p7, p8, p9, p10;

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

  PointerUint8x20({isLeaf: false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<Function20PointerUint8,
                Function20PointerUint8>('Function20PointerUint8', isLeaf: true)
            : ffiTestFunctions
                .lookupFunction<Function20PointerUint8, Function20PointerUint8>(
                    'Function20PointerUint8',
                    isLeaf: false),
        super('FfiCall.PointerUint8x20', isLeaf: isLeaf);

  Pointer<Uint8> p1,
      p2,
      p3,
      p4,
      p5,
      p6,
      p7,
      p8,
      p9,
      p10,
      p11,
      p12,
      p13,
      p14,
      p15,
      p16,
      p17,
      p18,
      p19,
      p20;

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

class MyClass {
  int a;
  MyClass(this.a);
}

class Handlex01 extends FfiBenchmarkBase {
  final Function1Object f;

  Handlex01()
      : f = ffiTestFunctions.lookupFunction<NativeFunction1Handle,
            Function1Object>('Function1Handle', isLeaf: false),
        super('FfiCall.Handlex01', isLeaf: false);

  @override
  void run() {
    final p1 = MyClass(123);
    Object x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x);
    }
    expectIdentical(x, p1);
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
    final p1 = MyClass(123);
    final p2 = MyClass(2);
    Object x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2);
    }
    expectIdentical(x, p1);
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
    final p1 = MyClass(123);
    final p2 = MyClass(2);
    final p3 = MyClass(3);
    final p4 = MyClass(4);
    Object x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2, p3, p4);
    }
    expectIdentical(x, p1);
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
    final p1 = MyClass(123);
    final p2 = MyClass(2);
    final p3 = MyClass(3);
    final p4 = MyClass(4);
    final p5 = MyClass(5);
    final p6 = MyClass(6);
    final p7 = MyClass(7);
    final p8 = MyClass(8);
    final p9 = MyClass(9);
    final p10 = MyClass(10);
    Object x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2, p3, p4, p5, p6, p7, p8, p9, p10);
    }
    expectIdentical(x, p1);
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
    final p1 = MyClass(123);
    final p2 = MyClass(2);
    final p3 = MyClass(3);
    final p4 = MyClass(4);
    final p5 = MyClass(5);
    final p6 = MyClass(6);
    final p7 = MyClass(7);
    final p8 = MyClass(8);
    final p9 = MyClass(9);
    final p10 = MyClass(10);
    final p11 = MyClass(11);
    final p12 = MyClass(12);
    final p13 = MyClass(13);
    final p14 = MyClass(14);
    final p15 = MyClass(15);
    final p16 = MyClass(16);
    final p17 = MyClass(17);
    final p18 = MyClass(18);
    final p19 = MyClass(19);
    final p20 = MyClass(20);
    Object x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15,
          p16, p17, p18, p19, p20);
    }
    expectIdentical(x, p1);
  }
}

//
// Main driver.
//

void main() {
  final benchmarks = [
    () => Uint8x01(),
    () => Uint8x01(isLeaf: true),
    () => Uint16x01(),
    () => Uint32x01(),
    () => Uint64x01(),
    () => Int8x01(),
    () => Int8x01(isLeaf: true),
    () => Int16x01(),
    () => Int32x01(),
    () => Int32x02(),
    () => Int32x04(),
    () => Int32x10(),
    () => Int32x20(),
    () => Int64x01(),
    () => Int64x02(),
    () => Int64x04(),
    () => Int64x10(),
    () => Int64x20(),
    () => Int64x20(isLeaf: true),
    () => Int64Mintx01(),
    () => Int64Mintx01(isLeaf: true),
    () => Floatx01(),
    () => Floatx02(),
    () => Floatx04(),
    () => Floatx10(),
    () => Floatx20(),
    () => Floatx20(isLeaf: true),
    () => Doublex01(),
    () => Doublex02(),
    () => Doublex04(),
    () => Doublex10(),
    () => Doublex20(),
    () => Doublex20(isLeaf: true),
    () => PointerUint8x01(),
    () => PointerUint8x02(),
    () => PointerUint8x04(),
    () => PointerUint8x10(),
    () => PointerUint8x20(),
    () => PointerUint8x20(isLeaf: true),
    () => Handlex01(),
    () => Handlex02(),
    () => Handlex04(),
    () => Handlex10(),
    () => Handlex20(),
  ];
  for (final benchmark in benchmarks) {
    benchmark().report();
  }
}
