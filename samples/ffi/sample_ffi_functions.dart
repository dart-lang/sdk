// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'dylib_utils.dart';

typedef NativeUnaryOp = ffi.Int32 Function(ffi.Int32);
typedef NativeBinaryOp = ffi.Int32 Function(ffi.Int32, ffi.Int32);
typedef UnaryOp = int Function(int);
typedef BinaryOp = int Function(int, int);
typedef GenericBinaryOp<T> = int Function(int, T);
typedef NativeQuadOpSigned = ffi.Int64 Function(
    ffi.Int64, ffi.Int32, ffi.Int16, ffi.Int8);
typedef NativeQuadOpUnsigned = ffi.Uint64 Function(
    ffi.Uint64, ffi.Uint32, ffi.Uint16, ffi.Uint8);
typedef NativeFunc4 = ffi.IntPtr Function(ffi.IntPtr);
typedef NativeDoubleUnaryOp = ffi.Double Function(ffi.Double);
typedef NativeFloatUnaryOp = ffi.Float Function(ffi.Float);
typedef NativeDecenaryOp = ffi.IntPtr Function(
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr);
typedef NativeDoubleDecenaryOp = ffi.Double Function(
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double);
typedef NativeVigesimalOp = ffi.Double Function(
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double,
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double,
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double,
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double,
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double);
typedef Int64PointerUnOp = ffi.Pointer<ffi.Int64> Function(
    ffi.Pointer<ffi.Int64>);
typedef QuadOp = int Function(int, int, int, int);
typedef DoubleUnaryOp = double Function(double);
typedef DecenaryOp = int Function(
    int, int, int, int, int, int, int, int, int, int);
typedef DoubleDecenaryOp = double Function(double, double, double, double,
    double, double, double, double, double, double);
typedef VigesimalOp = double Function(
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double);

main(List<String> arguments) {
  print('start main');

  ffi.DynamicLibrary ffiTestFunctions =
      dlopenPlatformSpecific("ffi_test_functions");

  {
    // int32 bin op
    BinaryOp sumPlus42 =
        ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");

    var result = sumPlus42(3, 17);
    print(result);
    print(result.runtimeType);
  }

  {
    // various size arguments
    QuadOp intComputation = ffiTestFunctions
        .lookupFunction<NativeQuadOpSigned, QuadOp>("IntComputation");
    var result = intComputation(125, 250, 500, 1000);
    print(result);
    print(result.runtimeType);

    var mint = 0x7FFFFFFFFFFFFFFF; // 2 ^ 63 - 1
    result = intComputation(1, 1, 0, mint);
    print(result);
    print(result.runtimeType);
  }

  {
    // unsigned int parameters
    QuadOp uintComputation = ffiTestFunctions
        .lookupFunction<NativeQuadOpUnsigned, QuadOp>("UintComputation");
    var result = uintComputation(0xFF, 0xFFFF, 0xFFFFFFFF, -1);
    result = uintComputation(1, 1, 0, -1);
    print(result);
    print(result.runtimeType);
    print(-0xFF + 0xFFFF - 0xFFFFFFFF);
  }

  {
    // architecture size argument
    ffi.Pointer<ffi.NativeFunction<NativeFunc4>> p =
        ffiTestFunctions.lookup("Times3");
    UnaryOp f6 = p.asFunction();
    var result = f6(1337);
    print(result);
    print(result.runtimeType);
  }

  {
    // function with double
    DoubleUnaryOp times1_337Double = ffiTestFunctions
        .lookupFunction<NativeDoubleUnaryOp, DoubleUnaryOp>("Times1_337Double");
    var result = times1_337Double(2.0);
    print(result);
    print(result.runtimeType);
  }

  {
    // function with float
    DoubleUnaryOp times1_337Float = ffiTestFunctions
        .lookupFunction<NativeFloatUnaryOp, DoubleUnaryOp>("Times1_337Float");
    var result = times1_337Float(1000.0);
    print(result);
    print(result.runtimeType);
  }

  {
    // function with many arguments: arguments get passed in registers and stack
    DecenaryOp sumManyInts = ffiTestFunctions
        .lookupFunction<NativeDecenaryOp, DecenaryOp>("SumManyInts");
    var result = sumManyInts(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    print(result);
    print(result.runtimeType);
  }

  {
    // function with many double arguments
    DoubleDecenaryOp sumManyDoubles = ffiTestFunctions.lookupFunction<
        NativeDoubleDecenaryOp, DoubleDecenaryOp>("SumManyDoubles");
    var result =
        sumManyDoubles(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0);
    print(result);
    print(result.runtimeType);
  }

  {
    // function with many arguments, ints and doubles mixed
    VigesimalOp sumManyNumbers = ffiTestFunctions
        .lookupFunction<NativeVigesimalOp, VigesimalOp>("SumManyNumbers");
    var result = sumManyNumbers(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0, 11,
        12.0, 13, 14.0, 15, 16.0, 17, 18.0, 19, 20.0);
    print(result);
    print(result.runtimeType);
  }

  {
    // pass an array / pointer as argument
    Int64PointerUnOp assign1337Index1 = ffiTestFunctions
        .lookupFunction<Int64PointerUnOp, Int64PointerUnOp>("Assign1337Index1");
    ffi.Pointer<ffi.Int64> p2 = ffi.allocate(count: 2);
    p2.store(42);
    p2.elementAt(1).store(1000);
    print(p2.elementAt(1).address.toRadixString(16));
    print(p2.elementAt(1).load<int>());
    ffi.Pointer<ffi.Int64> result = assign1337Index1(p2);
    print(p2.elementAt(1).load<int>());
    print(assign1337Index1);
    print(assign1337Index1.runtimeType);
    print(result);
    print(result.runtimeType);
    print(result.address.toRadixString(16));
    print(result.load<int>());
  }

  {
    // passing in null for an int argument throws a null pointer exception
    BinaryOp sumPlus42 =
        ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");

    int x = null;
    try {
      sumPlus42(43, x);
    } on ArgumentError {
      print('Expected exception on passing null for int');
    }
  }

  {
    // passing in null for a double argument throws a null pointer exception
    DoubleUnaryOp times1_337Double = ffiTestFunctions
        .lookupFunction<NativeDoubleUnaryOp, DoubleUnaryOp>("Times1_337Double");

    double x = null;
    try {
      times1_337Double(x);
    } on ArgumentError {
      print('Expected exception on passing null for double');
    }
  }

  {
    // passing in null for an int argument throws a null pointer exception
    VigesimalOp sumManyNumbers = ffiTestFunctions
        .lookupFunction<NativeVigesimalOp, VigesimalOp>("SumManyNumbers");

    int x = null;
    try {
      sumManyNumbers(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0, 11, 12.0, 13,
          14.0, 15, 16.0, 17, 18.0, x, 20.0);
    } on ArgumentError {
      print('Expected exception on passing null for int');
    }
  }

  {
    // passing in null for a pointer argument results in a nullptr in c
    Int64PointerUnOp nullableInt64ElemAt1 =
        ffiTestFunctions.lookupFunction<Int64PointerUnOp, Int64PointerUnOp>(
            "NullableInt64ElemAt1");

    ffi.Pointer<ffi.Int64> result = nullableInt64ElemAt1(null);
    print(result);
    print(result.runtimeType);

    ffi.Pointer<ffi.Int64> p2 = ffi.allocate(count: 2);
    result = nullableInt64ElemAt1(p2);
    print(result);
    print(result.runtimeType);
    p2.free();
  }

  print("end main");
}
