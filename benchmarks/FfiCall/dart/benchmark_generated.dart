// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, run the following script:
//
// > dart benchmarks/FfiCall/generate_benchmarks.dart

// Using part of, so that the library uri is identical to the main file.
// That way the FfiNativeResolver works for the main uri.
part of 'FfiCall.dart';

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

@Native<NativeFunction1Int8>(symbol: 'Function1Int8', isLeaf: false)
external int function1Int8(int a0);

class Int8x01Native extends FfiBenchmarkBase {
  Int8x01Native() : super('FfiCall.Int8x01Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Int8(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

@Native<NativeFunction1Int8>(symbol: 'Function1Int8', isLeaf: true)
external int function1Int8Leaf(int a0);

class Int8x01NativeLeaf extends FfiBenchmarkBase {
  Int8x01NativeLeaf() : super('FfiCall.Int8x01Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Int8Leaf(17);
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

@Native<NativeFunction1Int16>(symbol: 'Function1Int16', isLeaf: false)
external int function1Int16(int a0);

class Int16x01Native extends FfiBenchmarkBase {
  Int16x01Native() : super('FfiCall.Int16x01Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Int16(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

@Native<NativeFunction1Int16>(symbol: 'Function1Int16', isLeaf: true)
external int function1Int16Leaf(int a0);

class Int16x01NativeLeaf extends FfiBenchmarkBase {
  Int16x01NativeLeaf() : super('FfiCall.Int16x01Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Int16Leaf(17);
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

@Native<NativeFunction1Int32>(symbol: 'Function1Int32', isLeaf: false)
external int function1Int32(int a0);

class Int32x01Native extends FfiBenchmarkBase {
  Int32x01Native() : super('FfiCall.Int32x01Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Int32(i);
    }
    expectEquals(x, N * (N - 1) / 2 + N * 42);
  }
}

@Native<NativeFunction1Int32>(symbol: 'Function1Int32', isLeaf: true)
external int function1Int32Leaf(int a0);

class Int32x01NativeLeaf extends FfiBenchmarkBase {
  Int32x01NativeLeaf() : super('FfiCall.Int32x01Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Int32Leaf(i);
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

@Native<NativeFunction2Int32>(symbol: 'Function2Int32', isLeaf: false)
external int function2Int32(int a0, int a1);

class Int32x02Native extends FfiBenchmarkBase {
  Int32x02Native() : super('FfiCall.Int32x02Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function2Int32(i, i);
    }
    expectEquals(x, N * (N - 1) * 2 / 2);
  }
}

@Native<NativeFunction2Int32>(symbol: 'Function2Int32', isLeaf: true)
external int function2Int32Leaf(int a0, int a1);

class Int32x02NativeLeaf extends FfiBenchmarkBase {
  Int32x02NativeLeaf() : super('FfiCall.Int32x02Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function2Int32Leaf(i, i);
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

@Native<NativeFunction4Int32>(symbol: 'Function4Int32', isLeaf: false)
external int function4Int32(int a0, int a1, int a2, int a3);

class Int32x04Native extends FfiBenchmarkBase {
  Int32x04Native() : super('FfiCall.Int32x04Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function4Int32(i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 4 / 2);
  }
}

@Native<NativeFunction4Int32>(symbol: 'Function4Int32', isLeaf: true)
external int function4Int32Leaf(int a0, int a1, int a2, int a3);

class Int32x04NativeLeaf extends FfiBenchmarkBase {
  Int32x04NativeLeaf() : super('FfiCall.Int32x04Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function4Int32Leaf(i, i, i, i);
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

@Native<NativeFunction10Int32>(symbol: 'Function10Int32', isLeaf: false)
external int function10Int32(int a0, int a1, int a2, int a3, int a4, int a5,
    int a6, int a7, int a8, int a9);

class Int32x10Native extends FfiBenchmarkBase {
  Int32x10Native() : super('FfiCall.Int32x10Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function10Int32(i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 10 / 2);
  }
}

@Native<NativeFunction10Int32>(symbol: 'Function10Int32', isLeaf: true)
external int function10Int32Leaf(int a0, int a1, int a2, int a3, int a4, int a5,
    int a6, int a7, int a8, int a9);

class Int32x10NativeLeaf extends FfiBenchmarkBase {
  Int32x10NativeLeaf() : super('FfiCall.Int32x10Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function10Int32Leaf(i, i, i, i, i, i, i, i, i, i);
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

@Native<NativeFunction20Int32>(symbol: 'Function20Int32', isLeaf: false)
external int function20Int32(
    int a0,
    int a1,
    int a2,
    int a3,
    int a4,
    int a5,
    int a6,
    int a7,
    int a8,
    int a9,
    int a10,
    int a11,
    int a12,
    int a13,
    int a14,
    int a15,
    int a16,
    int a17,
    int a18,
    int a19);

class Int32x20Native extends FfiBenchmarkBase {
  Int32x20Native() : super('FfiCall.Int32x20Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function20Int32(
          i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 20 / 2);
  }
}

@Native<NativeFunction20Int32>(symbol: 'Function20Int32', isLeaf: true)
external int function20Int32Leaf(
    int a0,
    int a1,
    int a2,
    int a3,
    int a4,
    int a5,
    int a6,
    int a7,
    int a8,
    int a9,
    int a10,
    int a11,
    int a12,
    int a13,
    int a14,
    int a15,
    int a16,
    int a17,
    int a18,
    int a19);

class Int32x20NativeLeaf extends FfiBenchmarkBase {
  Int32x20NativeLeaf() : super('FfiCall.Int32x20Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function20Int32Leaf(
          i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i);
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

@Native<NativeFunction1Int64>(symbol: 'Function1Int64', isLeaf: false)
external int function1Int64(int a0);

class Int64x01Native extends FfiBenchmarkBase {
  Int64x01Native() : super('FfiCall.Int64x01Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Int64(i);
    }
    expectEquals(x, N * (N - 1) / 2 + N * 42);
  }
}

@Native<NativeFunction1Int64>(symbol: 'Function1Int64', isLeaf: true)
external int function1Int64Leaf(int a0);

class Int64x01NativeLeaf extends FfiBenchmarkBase {
  Int64x01NativeLeaf() : super('FfiCall.Int64x01Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Int64Leaf(i);
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

@Native<NativeFunction2Int64>(symbol: 'Function2Int64', isLeaf: false)
external int function2Int64(int a0, int a1);

class Int64x02Native extends FfiBenchmarkBase {
  Int64x02Native() : super('FfiCall.Int64x02Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function2Int64(i, i);
    }
    expectEquals(x, N * (N - 1) * 2 / 2);
  }
}

@Native<NativeFunction2Int64>(symbol: 'Function2Int64', isLeaf: true)
external int function2Int64Leaf(int a0, int a1);

class Int64x02NativeLeaf extends FfiBenchmarkBase {
  Int64x02NativeLeaf() : super('FfiCall.Int64x02Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function2Int64Leaf(i, i);
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

@Native<NativeFunction4Int64>(symbol: 'Function4Int64', isLeaf: false)
external int function4Int64(int a0, int a1, int a2, int a3);

class Int64x04Native extends FfiBenchmarkBase {
  Int64x04Native() : super('FfiCall.Int64x04Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function4Int64(i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 4 / 2);
  }
}

@Native<NativeFunction4Int64>(symbol: 'Function4Int64', isLeaf: true)
external int function4Int64Leaf(int a0, int a1, int a2, int a3);

class Int64x04NativeLeaf extends FfiBenchmarkBase {
  Int64x04NativeLeaf() : super('FfiCall.Int64x04Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function4Int64Leaf(i, i, i, i);
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

@Native<NativeFunction10Int64>(symbol: 'Function10Int64', isLeaf: false)
external int function10Int64(int a0, int a1, int a2, int a3, int a4, int a5,
    int a6, int a7, int a8, int a9);

class Int64x10Native extends FfiBenchmarkBase {
  Int64x10Native() : super('FfiCall.Int64x10Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function10Int64(i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 10 / 2);
  }
}

@Native<NativeFunction10Int64>(symbol: 'Function10Int64', isLeaf: true)
external int function10Int64Leaf(int a0, int a1, int a2, int a3, int a4, int a5,
    int a6, int a7, int a8, int a9);

class Int64x10NativeLeaf extends FfiBenchmarkBase {
  Int64x10NativeLeaf() : super('FfiCall.Int64x10Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function10Int64Leaf(i, i, i, i, i, i, i, i, i, i);
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

@Native<NativeFunction20Int64>(symbol: 'Function20Int64', isLeaf: false)
external int function20Int64(
    int a0,
    int a1,
    int a2,
    int a3,
    int a4,
    int a5,
    int a6,
    int a7,
    int a8,
    int a9,
    int a10,
    int a11,
    int a12,
    int a13,
    int a14,
    int a15,
    int a16,
    int a17,
    int a18,
    int a19);

class Int64x20Native extends FfiBenchmarkBase {
  Int64x20Native() : super('FfiCall.Int64x20Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function20Int64(
          i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 20 / 2);
  }
}

@Native<NativeFunction20Int64>(symbol: 'Function20Int64', isLeaf: true)
external int function20Int64Leaf(
    int a0,
    int a1,
    int a2,
    int a3,
    int a4,
    int a5,
    int a6,
    int a7,
    int a8,
    int a9,
    int a10,
    int a11,
    int a12,
    int a13,
    int a14,
    int a15,
    int a16,
    int a17,
    int a18,
    int a19);

class Int64x20NativeLeaf extends FfiBenchmarkBase {
  Int64x20NativeLeaf() : super('FfiCall.Int64x20Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function20Int64Leaf(
          i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i);
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

@Native<NativeFunction1Uint8>(symbol: 'Function1Uint8', isLeaf: false)
external int function1Uint8(int a0);

class Uint8x01Native extends FfiBenchmarkBase {
  Uint8x01Native() : super('FfiCall.Uint8x01Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Uint8(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

@Native<NativeFunction1Uint8>(symbol: 'Function1Uint8', isLeaf: true)
external int function1Uint8Leaf(int a0);

class Uint8x01NativeLeaf extends FfiBenchmarkBase {
  Uint8x01NativeLeaf() : super('FfiCall.Uint8x01Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Uint8Leaf(17);
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

@Native<NativeFunction1Uint16>(symbol: 'Function1Uint16', isLeaf: false)
external int function1Uint16(int a0);

class Uint16x01Native extends FfiBenchmarkBase {
  Uint16x01Native() : super('FfiCall.Uint16x01Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Uint16(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

@Native<NativeFunction1Uint16>(symbol: 'Function1Uint16', isLeaf: true)
external int function1Uint16Leaf(int a0);

class Uint16x01NativeLeaf extends FfiBenchmarkBase {
  Uint16x01NativeLeaf() : super('FfiCall.Uint16x01Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Uint16Leaf(17);
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

@Native<NativeFunction1Uint32>(symbol: 'Function1Uint32', isLeaf: false)
external int function1Uint32(int a0);

class Uint32x01Native extends FfiBenchmarkBase {
  Uint32x01Native() : super('FfiCall.Uint32x01Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Uint32(i);
    }
    expectEquals(x, N * (N - 1) / 2 + N * 42);
  }
}

@Native<NativeFunction1Uint32>(symbol: 'Function1Uint32', isLeaf: true)
external int function1Uint32Leaf(int a0);

class Uint32x01NativeLeaf extends FfiBenchmarkBase {
  Uint32x01NativeLeaf() : super('FfiCall.Uint32x01Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Uint32Leaf(i);
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

@Native<NativeFunction1Uint64>(symbol: 'Function1Uint64', isLeaf: false)
external int function1Uint64(int a0);

class Uint64x01Native extends FfiBenchmarkBase {
  Uint64x01Native() : super('FfiCall.Uint64x01Native', isLeaf: false);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Uint64(i);
    }
    expectEquals(x, N * (N - 1) / 2 + N * 42);
  }
}

@Native<NativeFunction1Uint64>(symbol: 'Function1Uint64', isLeaf: true)
external int function1Uint64Leaf(int a0);

class Uint64x01NativeLeaf extends FfiBenchmarkBase {
  Uint64x01NativeLeaf() : super('FfiCall.Uint64x01Native', isLeaf: true);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Uint64Leaf(i);
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

@Native<NativeFunction1Float>(symbol: 'Function1Float', isLeaf: false)
external double function1Float(double a0);

class Floatx01Native extends FfiBenchmarkBase {
  Floatx01Native() : super('FfiCall.Floatx01Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Float(1.0);
    }
    final double expected = N + N * 42.0;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction1Float>(symbol: 'Function1Float', isLeaf: true)
external double function1FloatLeaf(double a0);

class Floatx01NativeLeaf extends FfiBenchmarkBase {
  Floatx01NativeLeaf() : super('FfiCall.Floatx01Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function1FloatLeaf(1.0);
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

@Native<NativeFunction2Float>(symbol: 'Function2Float', isLeaf: false)
external double function2Float(double a0, double a1);

class Floatx02Native extends FfiBenchmarkBase {
  Floatx02Native() : super('FfiCall.Floatx02Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function2Float(1.0, 2.0);
    }
    final double expected = N * 2 * (2 + 1) / 2;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction2Float>(symbol: 'Function2Float', isLeaf: true)
external double function2FloatLeaf(double a0, double a1);

class Floatx02NativeLeaf extends FfiBenchmarkBase {
  Floatx02NativeLeaf() : super('FfiCall.Floatx02Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function2FloatLeaf(1.0, 2.0);
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

@Native<NativeFunction4Float>(symbol: 'Function4Float', isLeaf: false)
external double function4Float(double a0, double a1, double a2, double a3);

class Floatx04Native extends FfiBenchmarkBase {
  Floatx04Native() : super('FfiCall.Floatx04Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function4Float(1.0, 2.0, 3.0, 4.0);
    }
    final double expected = N * 4 * (4 + 1) / 2;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction4Float>(symbol: 'Function4Float', isLeaf: true)
external double function4FloatLeaf(double a0, double a1, double a2, double a3);

class Floatx04NativeLeaf extends FfiBenchmarkBase {
  Floatx04NativeLeaf() : super('FfiCall.Floatx04Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function4FloatLeaf(1.0, 2.0, 3.0, 4.0);
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

@Native<NativeFunction10Float>(symbol: 'Function10Float', isLeaf: false)
external double function10Float(double a0, double a1, double a2, double a3,
    double a4, double a5, double a6, double a7, double a8, double a9);

class Floatx10Native extends FfiBenchmarkBase {
  Floatx10Native() : super('FfiCall.Floatx10Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function10Float(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0);
    }
    final double expected = N * 10 * (10 + 1) / 2;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction10Float>(symbol: 'Function10Float', isLeaf: true)
external double function10FloatLeaf(double a0, double a1, double a2, double a3,
    double a4, double a5, double a6, double a7, double a8, double a9);

class Floatx10NativeLeaf extends FfiBenchmarkBase {
  Floatx10NativeLeaf() : super('FfiCall.Floatx10Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function10FloatLeaf(
          1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0);
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

@Native<NativeFunction20Float>(symbol: 'Function20Float', isLeaf: false)
external double function20Float(
    double a0,
    double a1,
    double a2,
    double a3,
    double a4,
    double a5,
    double a6,
    double a7,
    double a8,
    double a9,
    double a10,
    double a11,
    double a12,
    double a13,
    double a14,
    double a15,
    double a16,
    double a17,
    double a18,
    double a19);

class Floatx20Native extends FfiBenchmarkBase {
  Floatx20Native() : super('FfiCall.Floatx20Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function20Float(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
          11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0);
    }
    final double expected = N * 20 * (20 + 1) / 2;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction20Float>(symbol: 'Function20Float', isLeaf: true)
external double function20FloatLeaf(
    double a0,
    double a1,
    double a2,
    double a3,
    double a4,
    double a5,
    double a6,
    double a7,
    double a8,
    double a9,
    double a10,
    double a11,
    double a12,
    double a13,
    double a14,
    double a15,
    double a16,
    double a17,
    double a18,
    double a19);

class Floatx20NativeLeaf extends FfiBenchmarkBase {
  Floatx20NativeLeaf() : super('FfiCall.Floatx20Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function20FloatLeaf(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0,
          10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0);
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

@Native<NativeFunction1Double>(symbol: 'Function1Double', isLeaf: false)
external double function1Double(double a0);

class Doublex01Native extends FfiBenchmarkBase {
  Doublex01Native() : super('FfiCall.Doublex01Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function1Double(1.0);
    }
    final double expected = N + N * 42.0;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction1Double>(symbol: 'Function1Double', isLeaf: true)
external double function1DoubleLeaf(double a0);

class Doublex01NativeLeaf extends FfiBenchmarkBase {
  Doublex01NativeLeaf() : super('FfiCall.Doublex01Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function1DoubleLeaf(1.0);
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

@Native<NativeFunction2Double>(symbol: 'Function2Double', isLeaf: false)
external double function2Double(double a0, double a1);

class Doublex02Native extends FfiBenchmarkBase {
  Doublex02Native() : super('FfiCall.Doublex02Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function2Double(1.0, 2.0);
    }
    final double expected = N * 2 * (2 + 1) / 2;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction2Double>(symbol: 'Function2Double', isLeaf: true)
external double function2DoubleLeaf(double a0, double a1);

class Doublex02NativeLeaf extends FfiBenchmarkBase {
  Doublex02NativeLeaf() : super('FfiCall.Doublex02Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function2DoubleLeaf(1.0, 2.0);
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

@Native<NativeFunction4Double>(symbol: 'Function4Double', isLeaf: false)
external double function4Double(double a0, double a1, double a2, double a3);

class Doublex04Native extends FfiBenchmarkBase {
  Doublex04Native() : super('FfiCall.Doublex04Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function4Double(1.0, 2.0, 3.0, 4.0);
    }
    final double expected = N * 4 * (4 + 1) / 2;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction4Double>(symbol: 'Function4Double', isLeaf: true)
external double function4DoubleLeaf(double a0, double a1, double a2, double a3);

class Doublex04NativeLeaf extends FfiBenchmarkBase {
  Doublex04NativeLeaf() : super('FfiCall.Doublex04Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function4DoubleLeaf(1.0, 2.0, 3.0, 4.0);
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

@Native<NativeFunction10Double>(symbol: 'Function10Double', isLeaf: false)
external double function10Double(double a0, double a1, double a2, double a3,
    double a4, double a5, double a6, double a7, double a8, double a9);

class Doublex10Native extends FfiBenchmarkBase {
  Doublex10Native() : super('FfiCall.Doublex10Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function10Double(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0);
    }
    final double expected = N * 10 * (10 + 1) / 2;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction10Double>(symbol: 'Function10Double', isLeaf: true)
external double function10DoubleLeaf(double a0, double a1, double a2, double a3,
    double a4, double a5, double a6, double a7, double a8, double a9);

class Doublex10NativeLeaf extends FfiBenchmarkBase {
  Doublex10NativeLeaf() : super('FfiCall.Doublex10Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function10DoubleLeaf(
          1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0);
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

@Native<NativeFunction20Double>(symbol: 'Function20Double', isLeaf: false)
external double function20Double(
    double a0,
    double a1,
    double a2,
    double a3,
    double a4,
    double a5,
    double a6,
    double a7,
    double a8,
    double a9,
    double a10,
    double a11,
    double a12,
    double a13,
    double a14,
    double a15,
    double a16,
    double a17,
    double a18,
    double a19);

class Doublex20Native extends FfiBenchmarkBase {
  Doublex20Native() : super('FfiCall.Doublex20Native', isLeaf: false);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function20Double(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
          11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0);
    }
    final double expected = N * 20 * (20 + 1) / 2;
    expectApprox(x, expected);
  }
}

@Native<NativeFunction20Double>(symbol: 'Function20Double', isLeaf: true)
external double function20DoubleLeaf(
    double a0,
    double a1,
    double a2,
    double a3,
    double a4,
    double a5,
    double a6,
    double a7,
    double a8,
    double a9,
    double a10,
    double a11,
    double a12,
    double a13,
    double a14,
    double a15,
    double a16,
    double a17,
    double a18,
    double a19);

class Doublex20NativeLeaf extends FfiBenchmarkBase {
  Doublex20NativeLeaf() : super('FfiCall.Doublex20Native', isLeaf: true);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += function20DoubleLeaf(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0,
          10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0);
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

@Native<NativeFunction1PointerUint8>(
    symbol: 'Function1PointerUint8', isLeaf: false)
external Pointer<Uint8> function1PointerUint8(Pointer<Uint8> a0);

class PointerUint8x01Native extends FfiBenchmarkBase {
  PointerUint8x01Native()
      : super('FfiCall.PointerUint8x01Native', isLeaf: false);

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
      x = function1PointerUint8(
        x,
      );
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

@Native<NativeFunction1PointerUint8>(
    symbol: 'Function1PointerUint8', isLeaf: true)
external Pointer<Uint8> function1PointerUint8Leaf(Pointer<Uint8> a0);

class PointerUint8x01NativeLeaf extends FfiBenchmarkBase {
  PointerUint8x01NativeLeaf()
      : super('FfiCall.PointerUint8x01Native', isLeaf: true);

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
      x = function1PointerUint8Leaf(
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

@Native<NativeFunction2PointerUint8>(
    symbol: 'Function2PointerUint8', isLeaf: false)
external Pointer<Uint8> function2PointerUint8(
    Pointer<Uint8> a0, Pointer<Uint8> a1);

class PointerUint8x02Native extends FfiBenchmarkBase {
  PointerUint8x02Native()
      : super('FfiCall.PointerUint8x02Native', isLeaf: false);

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
      x = function2PointerUint8(x, p2);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

@Native<NativeFunction2PointerUint8>(
    symbol: 'Function2PointerUint8', isLeaf: true)
external Pointer<Uint8> function2PointerUint8Leaf(
    Pointer<Uint8> a0, Pointer<Uint8> a1);

class PointerUint8x02NativeLeaf extends FfiBenchmarkBase {
  PointerUint8x02NativeLeaf()
      : super('FfiCall.PointerUint8x02Native', isLeaf: true);

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
      x = function2PointerUint8Leaf(x, p2);
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

@Native<NativeFunction4PointerUint8>(
    symbol: 'Function4PointerUint8', isLeaf: false)
external Pointer<Uint8> function4PointerUint8(
    Pointer<Uint8> a0, Pointer<Uint8> a1, Pointer<Uint8> a2, Pointer<Uint8> a3);

class PointerUint8x04Native extends FfiBenchmarkBase {
  PointerUint8x04Native()
      : super('FfiCall.PointerUint8x04Native', isLeaf: false);

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
      x = function4PointerUint8(x, p2, p3, p4);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

@Native<NativeFunction4PointerUint8>(
    symbol: 'Function4PointerUint8', isLeaf: true)
external Pointer<Uint8> function4PointerUint8Leaf(
    Pointer<Uint8> a0, Pointer<Uint8> a1, Pointer<Uint8> a2, Pointer<Uint8> a3);

class PointerUint8x04NativeLeaf extends FfiBenchmarkBase {
  PointerUint8x04NativeLeaf()
      : super('FfiCall.PointerUint8x04Native', isLeaf: true);

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
      x = function4PointerUint8Leaf(x, p2, p3, p4);
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

@Native<NativeFunction10PointerUint8>(
    symbol: 'Function10PointerUint8', isLeaf: false)
external Pointer<Uint8> function10PointerUint8(
    Pointer<Uint8> a0,
    Pointer<Uint8> a1,
    Pointer<Uint8> a2,
    Pointer<Uint8> a3,
    Pointer<Uint8> a4,
    Pointer<Uint8> a5,
    Pointer<Uint8> a6,
    Pointer<Uint8> a7,
    Pointer<Uint8> a8,
    Pointer<Uint8> a9);

class PointerUint8x10Native extends FfiBenchmarkBase {
  PointerUint8x10Native()
      : super('FfiCall.PointerUint8x10Native', isLeaf: false);

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
      x = function10PointerUint8(x, p2, p3, p4, p5, p6, p7, p8, p9, p10);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

@Native<NativeFunction10PointerUint8>(
    symbol: 'Function10PointerUint8', isLeaf: true)
external Pointer<Uint8> function10PointerUint8Leaf(
    Pointer<Uint8> a0,
    Pointer<Uint8> a1,
    Pointer<Uint8> a2,
    Pointer<Uint8> a3,
    Pointer<Uint8> a4,
    Pointer<Uint8> a5,
    Pointer<Uint8> a6,
    Pointer<Uint8> a7,
    Pointer<Uint8> a8,
    Pointer<Uint8> a9);

class PointerUint8x10NativeLeaf extends FfiBenchmarkBase {
  PointerUint8x10NativeLeaf()
      : super('FfiCall.PointerUint8x10Native', isLeaf: true);

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
      x = function10PointerUint8Leaf(x, p2, p3, p4, p5, p6, p7, p8, p9, p10);
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

@Native<NativeFunction20PointerUint8>(
    symbol: 'Function20PointerUint8', isLeaf: false)
external Pointer<Uint8> function20PointerUint8(
    Pointer<Uint8> a0,
    Pointer<Uint8> a1,
    Pointer<Uint8> a2,
    Pointer<Uint8> a3,
    Pointer<Uint8> a4,
    Pointer<Uint8> a5,
    Pointer<Uint8> a6,
    Pointer<Uint8> a7,
    Pointer<Uint8> a8,
    Pointer<Uint8> a9,
    Pointer<Uint8> a10,
    Pointer<Uint8> a11,
    Pointer<Uint8> a12,
    Pointer<Uint8> a13,
    Pointer<Uint8> a14,
    Pointer<Uint8> a15,
    Pointer<Uint8> a16,
    Pointer<Uint8> a17,
    Pointer<Uint8> a18,
    Pointer<Uint8> a19);

class PointerUint8x20Native extends FfiBenchmarkBase {
  PointerUint8x20Native()
      : super('FfiCall.PointerUint8x20Native', isLeaf: false);

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
      x = function20PointerUint8(x, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11,
          p12, p13, p14, p15, p16, p17, p18, p19, p20);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}

@Native<NativeFunction20PointerUint8>(
    symbol: 'Function20PointerUint8', isLeaf: true)
external Pointer<Uint8> function20PointerUint8Leaf(
    Pointer<Uint8> a0,
    Pointer<Uint8> a1,
    Pointer<Uint8> a2,
    Pointer<Uint8> a3,
    Pointer<Uint8> a4,
    Pointer<Uint8> a5,
    Pointer<Uint8> a6,
    Pointer<Uint8> a7,
    Pointer<Uint8> a8,
    Pointer<Uint8> a9,
    Pointer<Uint8> a10,
    Pointer<Uint8> a11,
    Pointer<Uint8> a12,
    Pointer<Uint8> a13,
    Pointer<Uint8> a14,
    Pointer<Uint8> a15,
    Pointer<Uint8> a16,
    Pointer<Uint8> a17,
    Pointer<Uint8> a18,
    Pointer<Uint8> a19);

class PointerUint8x20NativeLeaf extends FfiBenchmarkBase {
  PointerUint8x20NativeLeaf()
      : super('FfiCall.PointerUint8x20Native', isLeaf: true);

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
      x = function20PointerUint8Leaf(x, p2, p3, p4, p5, p6, p7, p8, p9, p10,
          p11, p12, p13, p14, p15, p16, p17, p18, p19, p20);
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

@Native<NativeFunction1Handle>(symbol: 'Function1Handle', isLeaf: false)
external Object function1Handle(Object a0);

class Handlex01Native extends FfiBenchmarkBase {
  Handlex01Native() : super('FfiCall.Handlex01Native', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);

    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = function1Handle(
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

@Native<NativeFunction2Handle>(symbol: 'Function2Handle', isLeaf: false)
external Object function2Handle(Object a0, Object a1);

class Handlex02Native extends FfiBenchmarkBase {
  Handlex02Native() : super('FfiCall.Handlex02Native', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);
    final m2 = MyClass(2);
    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = function2Handle(x, m2);
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

@Native<NativeFunction4Handle>(symbol: 'Function4Handle', isLeaf: false)
external Object function4Handle(Object a0, Object a1, Object a2, Object a3);

class Handlex04Native extends FfiBenchmarkBase {
  Handlex04Native() : super('FfiCall.Handlex04Native', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);
    final m2 = MyClass(2);
    final m3 = MyClass(3);
    final m4 = MyClass(4);
    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = function4Handle(x, m2, m3, m4);
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

@Native<NativeFunction10Handle>(symbol: 'Function10Handle', isLeaf: false)
external Object function10Handle(Object a0, Object a1, Object a2, Object a3,
    Object a4, Object a5, Object a6, Object a7, Object a8, Object a9);

class Handlex10Native extends FfiBenchmarkBase {
  Handlex10Native() : super('FfiCall.Handlex10Native', isLeaf: false);

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
      x = function10Handle(x, m2, m3, m4, m5, m6, m7, m8, m9, m10);
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

@Native<NativeFunction20Handle>(symbol: 'Function20Handle', isLeaf: false)
external Object function20Handle(
    Object a0,
    Object a1,
    Object a2,
    Object a3,
    Object a4,
    Object a5,
    Object a6,
    Object a7,
    Object a8,
    Object a9,
    Object a10,
    Object a11,
    Object a12,
    Object a13,
    Object a14,
    Object a15,
    Object a16,
    Object a17,
    Object a18,
    Object a19);

class Handlex20Native extends FfiBenchmarkBase {
  Handlex20Native() : super('FfiCall.Handlex20Native', isLeaf: false);

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
      x = function20Handle(x, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12,
          m13, m14, m15, m16, m17, m18, m19, m20);
    }
    expectIdentical(x, m1);
  }
}
