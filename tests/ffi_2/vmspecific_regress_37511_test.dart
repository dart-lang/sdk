// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi struct pointers.
//
// VMOptions=--deterministic --enable-testing-pragmas
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dylib_utils.dart';
import 'ffi_test_helpers.dart';

/// Estimate of how many allocations functions in `functionsToTest` do at most.
const gcAfterNAllocationsMax = 10;

void main() {
  for (Function() f in functionsToTest) {
    f(); // Ensure code is compiled.

    for (int n = 1; n <= gcAfterNAllocationsMax; n++) {
      collectOnNthAllocation(n);
      f();
    }
  }
}

final List<Function()> functionsToTest = [
  // Pointer operations.
  () => highAddressPointer.cast<Double>(),
  () => Pointer.fromAddress(highAddressPointer.address),
  () => highAddressPointer.address,
  () => highAddressPointer.elementAt(1),
  () => highAddressPointer.offsetBy(1),
  () => highAddressPointer.asTypedList(1),

  // DynamicLibrary operations.
  doDlopen,
  doDlsym, // Includes `asFunction`.
  () => ffiTestFunctions.handle,

  // Trampolines.
  () => sumManyIntsOdd(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, mint64bit),
  () => sumManyDoubles(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0),
  minInt64,
  minInt32,
  smallDouble,
  largePointer,

  // Callback trampolines.
  //
  // In regress_37511_callbacks_test.dart because callbacks are not supported
  // in AOT yet.
];

// Pointer operation helpers.
const mint32bit = 0xFFFFFFF0;
const mint64bit = 0x7FFFFFFFFFFFFFF0;

final int highAddress = sizeOf<IntPtr>() == 4 ? mint32bit : mint64bit;

final Pointer<Int64> highAddressPointer = Pointer.fromAddress(highAddress);

// Dynamic library operation helpers.
final doDlopen = () => dlopenPlatformSpecific("ffi_test_functions");

final doDlsym = () => ffiTestFunctions
    .lookupFunction<NativeNullaryOp, NullaryOpVoid>("TriggerGC");

// Trampoline helpers.
typedef NativeUndenaryOp = IntPtr Function(IntPtr, IntPtr, IntPtr, IntPtr,
    IntPtr, IntPtr, IntPtr, IntPtr, IntPtr, IntPtr, IntPtr);
typedef UndenaryOp = int Function(
    int, int, int, int, int, int, int, int, int, int, int);

final UndenaryOp sumManyIntsOdd = ffiTestFunctions
    .lookupFunction<NativeUndenaryOp, UndenaryOp>("SumManyIntsOdd");

typedef NativeDoubleDecenaryOp = Double Function(Double, Double, Double, Double,
    Double, Double, Double, Double, Double, Double);
typedef DoubleDecenaryOp = double Function(double, double, double, double,
    double, double, double, double, double, double);

final DoubleDecenaryOp sumManyDoubles = ffiTestFunctions
    .lookupFunction<NativeDoubleDecenaryOp, DoubleDecenaryOp>("SumManyDoubles");

typedef NativeNullaryOp64 = Int64 Function();
typedef NativeNullaryOp32 = Int32 Function();
typedef NativeNullaryOpDouble = Double Function();
typedef NullaryOpPtr = Pointer<Void> Function();
typedef NullaryOp = int Function();
typedef NullaryOpDbl = double Function();

final minInt64 =
    ffiTestFunctions.lookupFunction<NativeNullaryOp64, NullaryOp>("MinInt64");

final minInt32 =
    ffiTestFunctions.lookupFunction<NativeNullaryOp32, NullaryOp>("MinInt32");

final smallDouble = ffiTestFunctions
    .lookupFunction<NativeNullaryOpDouble, NullaryOpDbl>("SmallDouble");

final largePointer =
    ffiTestFunctions.lookupFunction<NullaryOpPtr, NullaryOpPtr>("LargePointer");
