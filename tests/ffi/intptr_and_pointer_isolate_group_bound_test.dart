// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions
// VMOptions=--experimental-shared-data
// VMOptions=--experimental-shared-data --sim_buffer_memory

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

typedef NativeTwoIntCallback = Int32 Function(Int32, Int32);
typedef NativeCallTwoIntFn =
    Int32 Function(Pointer<NativeFunction<NativeTwoIntCallback>>, Int32, Int32);
typedef CallTwoIntFn =
    int Function(Pointer<NativeFunction<NativeTwoIntCallback>>, int, int);

final callTwoIntFunction = ffiTestFunctions
    .lookupFunction<NativeCallTwoIntFn, CallTwoIntFn>('CallTwoIntFunction');

final callTwoIntFunctionOnNewThread = ffiTestFunctions
    .lookupFunction<NativeCallTwoIntFn, CallTwoIntFn>(
      'CallTwoIntFunctionOnNewThread',
    );

typedef NativeBoolPointerCallback = Bool Function(Pointer<Void>);
typedef NativeCallBoolPointerFn =
    Bool Function(
      Pointer<NativeFunction<NativeBoolPointerCallback>>,
      Pointer<Void>,
    );
typedef CallBoolPointerFn =
    bool Function(
      Pointer<NativeFunction<NativeBoolPointerCallback>>,
      Pointer<Void>,
    );

final callBoolPointerFunction = ffiTestFunctions
    .lookupFunction<NativeCallBoolPointerFn, CallBoolPointerFn>(
      'CallBoolPointerFunction',
    );

typedef NativeEightIntPtrCallback =
    IntPtr Function(
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
    );
typedef NativeCallEightIntPtrFn =
    IntPtr Function(
      Pointer<NativeFunction<NativeEightIntPtrCallback>>,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
    );
typedef CallEightIntPtrFn =
    int Function(
      Pointer<NativeFunction<NativeEightIntPtrCallback>>,
      int,
      int,
      int,
      int,
      int,
      int,
      int,
      int,
    );

final callEightIntPtrFunction = ffiTestFunctions
    .lookupFunction<NativeCallEightIntPtrFn, CallEightIntPtrFn>(
      'CallEightIntPtrFunction',
    );

typedef NativeMutateIntPtrCallback = Void Function(Pointer<IntPtr>);
typedef NativeCallCallbackAndReadMemoryFn =
    IntPtr Function(
      Pointer<NativeFunction<NativeMutateIntPtrCallback>>,
      IntPtr,
    );
typedef CallCallbackAndReadMemoryFn =
    int Function(Pointer<NativeFunction<NativeMutateIntPtrCallback>>, int);

final callCallbackAndReadMemory = ffiTestFunctions
    .lookupFunction<
      NativeCallCallbackAndReadMemoryFn,
      CallCallbackAndReadMemoryFn
    >('CallCallbackAndReadMemory');

int twoIntCallback(int a, int b) => a * 10 + b;

bool boolPointerCallback(Pointer<Void> ptr) => ptr.address == 123;

int eightIntPtrCallback(
  int a0,
  int a1,
  int a2,
  int a3,
  int a4,
  int a5,
  int a6,
  int a7,
) => a0 - a1 + a2 - a3 + a4 - a5 + a6 - a7;

void mutateIntPtrCallback(Pointer<IntPtr> ptr) {
  ptr.value = ptr.value * 3 + 7;
}

void main() {
  // Same thread: 2 Int32 arguments.
  final twoInt = NativeCallable<NativeTwoIntCallback>.isolateGroupBound(
    twoIntCallback,
    exceptionalReturn: 0,
  );
  Expect.equals(42, callTwoIntFunction(twoInt.nativeFunction, 4, 2));
  Expect.equals(-38, callTwoIntFunction(twoInt.nativeFunction, -4, 2));

  // Brand-new native thread that has never called Simulator::Call()
  // (exercises fresh simulator stack alignment).
  Expect.equals(73, callTwoIntFunctionOnNewThread(twoInt.nativeFunction, 7, 3));
  twoInt.close();

  // Bool + Pointer.
  final boolPtr = NativeCallable<NativeBoolPointerCallback>.isolateGroupBound(
    boolPointerCallback,
    exceptionalReturn: false,
  );
  Expect.equals(
    true,
    callBoolPointerFunction(boolPtr.nativeFunction, Pointer.fromAddress(123)),
  );
  Expect.equals(
    false,
    callBoolPointerFunction(boolPtr.nativeFunction, Pointer.fromAddress(456)),
  );
  boolPtr.close();

  // 8 IntPtr arguments.
  final eightArgs = NativeCallable<NativeEightIntPtrCallback>.isolateGroupBound(
    eightIntPtrCallback,
    exceptionalReturn: 0,
  );
  Expect.equals(
    10 - 20 + 30 - 40 + 50 - 60 + 70 - 80,
    callEightIntPtrFunction(
      eightArgs.nativeFunction,
      10,
      20,
      30,
      40,
      50,
      60,
      70,
      80,
    ),
  );
  eightArgs.close();

  // Mutating memory from inside a callback and reading it back in C
  // (exercises BufferedSimulatorMemory flush under --sim_buffer_memory).
  final mutatePtr = Pointer.fromFunction<NativeMutateIntPtrCallback>(
    mutateIntPtrCallback,
  );
  Expect.equals(37, callCallbackAndReadMemory(mutatePtr, 10));

  final mutateCallable =
      NativeCallable<NativeMutateIntPtrCallback>.isolateGroupBound(
        mutateIntPtrCallback,
      );
  Expect.equals(
    67,
    callCallbackAndReadMemory(mutateCallable.nativeFunction, 20),
  );
  mutateCallable.close();
}
