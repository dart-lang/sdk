// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi struct pointers.
//
// VMOptions=--deterministic --enable-testing-pragmas
//
// SharedObjects=ffi_test_functions
//
// TODO(37295): Merge this file with regress_37511_test.dart when callback
// support lands.

import 'dart:ffi';

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
  // Callback trampolines.
  doFromFunction,
  () => callbackSmallDouble(dartFunctionPointer),
];

// Callback trampoline helpers.
typedef NativeCallbackTest = Int32 Function(Pointer);
typedef NativeCallbackTestFn = int Function(Pointer);

final callbackSmallDouble =
    ffiTestFunctions.lookupFunction<NativeCallbackTest, NativeCallbackTestFn>(
        "TestSimpleMultiply");

typedef SimpleMultiplyType = Double Function(Double);
double simpleMultiply(double x) => x * 1.337;

final doFromFunction =
    () => Pointer.fromFunction<SimpleMultiplyType>(simpleMultiply, 0.0);

final dartFunctionPointer = doFromFunction();
