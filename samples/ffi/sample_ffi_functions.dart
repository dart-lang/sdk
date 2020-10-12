// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';

typedef NativeUnaryOp = Int32 Function(Int32);
typedef NativeBinaryOp = Int32 Function(Int32, Int32);
typedef UnaryOp = int Function(int);
typedef BinaryOp = int Function(int, int);
typedef GenericBinaryOp<T> = int Function(int, T);
typedef NativeQuadOpSigned = Int64 Function(Int64, Int32, Int16, Int8);
typedef NativeQuadOpUnsigned = Uint64 Function(Uint64, Uint32, Uint16, Uint8);
typedef NativeFunc4 = IntPtr Function(IntPtr);
typedef NativeDoubleUnaryOp = Double Function(Double);
typedef NativeFloatUnaryOp = Float Function(Float);
typedef NativeDecenaryOp = IntPtr Function(IntPtr, IntPtr, IntPtr, IntPtr,
    IntPtr, IntPtr, IntPtr, IntPtr, IntPtr, IntPtr);
typedef NativeDecenaryOp2 = Int16 Function(
    Int8, Int16, Int8, Int16, Int8, Int16, Int8, Int16, Int8, Int16);
typedef NativeDoubleDecenaryOp = Double Function(Double, Double, Double, Double,
    Double, Double, Double, Double, Double, Double);
typedef NativeVigesimalOp = Double Function(
    IntPtr,
    Float,
    IntPtr,
    Double,
    IntPtr,
    Float,
    IntPtr,
    Double,
    IntPtr,
    Float,
    IntPtr,
    Double,
    IntPtr,
    Float,
    IntPtr,
    Double,
    IntPtr,
    Float,
    IntPtr,
    Double);
typedef Int64PointerUnOp = Pointer<Int64> Function(Pointer<Int64>);
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

main() {
  print('start main');

  DynamicLibrary ffiTestFunctions =
      dlopenPlatformSpecific("ffi_test_functions");

  {
    // A int32 bin op.
    BinaryOp sumPlus42 =
        ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");

    var result = sumPlus42(3, 17);
    print(result);
    print(result.runtimeType);
  }

  {
    // Various size arguments.
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
    // Unsigned int parameters.
    QuadOp uintComputation = ffiTestFunctions
        .lookupFunction<NativeQuadOpUnsigned, QuadOp>("UintComputation");
    var result = uintComputation(0xFF, 0xFFFF, 0xFFFFFFFF, -1);
    result = uintComputation(1, 1, 0, -1);
    print(result);
    print(result.runtimeType);
    print(-0xFF + 0xFFFF - 0xFFFFFFFF);
  }

  {
    // Architecture size argument.
    Pointer<NativeFunction<NativeFunc4>> p = ffiTestFunctions.lookup("Times3");
    UnaryOp f6 = p.asFunction();
    var result = f6(1337);
    print(result);
    print(result.runtimeType);
  }

  {
    // Function with double.
    DoubleUnaryOp times1_337Double = ffiTestFunctions
        .lookupFunction<NativeDoubleUnaryOp, DoubleUnaryOp>("Times1_337Double");
    var result = times1_337Double(2.0);
    print(result);
    print(result.runtimeType);
  }

  {
    // Function with float.
    DoubleUnaryOp times1_337Float = ffiTestFunctions
        .lookupFunction<NativeFloatUnaryOp, DoubleUnaryOp>("Times1_337Float");
    var result = times1_337Float(1000.0);
    print(result);
    print(result.runtimeType);
  }

  {
    // Function with many arguments: arguments get passed in registers and stack.
    DecenaryOp sumManyInts = ffiTestFunctions
        .lookupFunction<NativeDecenaryOp, DecenaryOp>("SumManyInts");
    var result = sumManyInts(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    print(result);
    print(result.runtimeType);
  }

  {
    // Function with many arguments: arguments get passed in registers and stack.
    DecenaryOp sumManyInts = ffiTestFunctions
        .lookupFunction<NativeDecenaryOp2, DecenaryOp>("SumManySmallInts");
    var result = sumManyInts(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    print(result);
    print(result.runtimeType);
  }

  {
    // Function with many double arguments.
    DoubleDecenaryOp sumManyDoubles = ffiTestFunctions.lookupFunction<
        NativeDoubleDecenaryOp, DoubleDecenaryOp>("SumManyDoubles");
    var result =
        sumManyDoubles(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0);
    print(result);
    print(result.runtimeType);
  }

  {
    // Function with many arguments, ints and doubles mixed.
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
    Pointer<Int64> p2 = allocate(count: 2);
    p2.value = 42;
    p2[1] = 1000;
    print(p2.elementAt(1).address.toRadixString(16));
    print(p2[1]);
    Pointer<Int64> result = assign1337Index1(p2);
    print(p2[1]);
    print(assign1337Index1);
    print(assign1337Index1.runtimeType);
    print(result);
    print(result.runtimeType);
    print(result.address.toRadixString(16));
    print(result.value);
  }

  {
    // Passing in null for an int argument throws a null pointer exception.
    BinaryOp sumPlus42 =
        ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");

    int x = null;
    try {
      sumPlus42(43, x);
    } on Error {
      print('Expected exception on passing null for int');
    }
  }

  {
    // Passing in null for a double argument throws a null pointer exception.
    DoubleUnaryOp times1_337Double = ffiTestFunctions
        .lookupFunction<NativeDoubleUnaryOp, DoubleUnaryOp>("Times1_337Double");

    double x = null;
    try {
      times1_337Double(x);
    } on Error {
      print('Expected exception on passing null for double');
    }
  }

  {
    // Passing in null for an int argument throws a null pointer exception.
    VigesimalOp sumManyNumbers = ffiTestFunctions
        .lookupFunction<NativeVigesimalOp, VigesimalOp>("SumManyNumbers");

    int x = null;
    try {
      sumManyNumbers(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0, 11, 12.0, 13,
          14.0, 15, 16.0, 17, 18.0, x, 20.0);
    } on Error {
      print('Expected exception on passing null for int');
    }
  }

  {
    // Passing in nullptr for a pointer argument results in a nullptr in c.
    Int64PointerUnOp nullableInt64ElemAt1 =
        ffiTestFunctions.lookupFunction<Int64PointerUnOp, Int64PointerUnOp>(
            "NullableInt64ElemAt1");

    Pointer<Int64> result = nullableInt64ElemAt1(nullptr);
    print(result);
    print(result.runtimeType);

    Pointer<Int64> p2 = allocate(count: 2);
    result = nullableInt64ElemAt1(p2);
    print(result);
    print(result.runtimeType);
    free(p2);
  }

  print("end main");
}
