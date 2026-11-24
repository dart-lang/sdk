// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';

final DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific(
  "ffi_test_functions",
);

final class Coord extends Struct {
  @Double()
  external double x;
  @Double()
  external double y;
}

// @Native with unsupported signatures.
@Native<Double Function()>()
external double unsupportedNativeFloatReturn();

@Native<Void Function(Coord)>()
external void unsupportedNativeStructArg(Coord c);

@Native<Coord Function()>()
external Coord unsupportedNativeStructReturn();

@Native<
  IntPtr Function(
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
    IntPtr,
  )
>()
external int unsupportedNative13Args(
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
);

void testNativeCalls() {
  final coord = calloc<Coord>();
  coord.ref.x = 1.0;
  coord.ref.y = 2.0;

  // @Native float return.
  Expect.throws<UnsupportedError>(() {
    unsupportedNativeFloatReturn();
  });

  // @Native struct by value argument.
  Expect.throws<UnsupportedError>(() {
    unsupportedNativeStructArg(coord.ref);
  });

  // @Native struct by value return.
  Expect.throws<UnsupportedError>(() {
    unsupportedNativeStructReturn();
  });

  // @Native > 12 arguments.
  Expect.throws<UnsupportedError>(() {
    unsupportedNative13Args(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
  });

  calloc.free(coord);
}

void testAsFunctionCalls() {
  final dummyPtr = Pointer<NativeFunction<Void Function()>>.fromAddress(0x1234);
  final coord = calloc<Coord>();
  coord.ref.x = 1.0;
  coord.ref.y = 2.0;

  // Float argument.
  final floatArg = dummyPtr
      .cast<NativeFunction<Void Function(Float)>>()
      .asFunction<void Function(double)>();
  Expect.throws<UnsupportedError>(() => floatArg(1.0));

  // Double argument.
  final doubleArg = dummyPtr
      .cast<NativeFunction<Void Function(Double)>>()
      .asFunction<void Function(double)>();
  Expect.throws<UnsupportedError>(() => doubleArg(1.0));

  // Double return.
  final doubleReturn = dummyPtr
      .cast<NativeFunction<Double Function()>>()
      .asFunction<double Function()>();
  Expect.throws<UnsupportedError>(() => doubleReturn());

  // Struct by value argument.
  final structArg = dummyPtr
      .cast<NativeFunction<Void Function(Coord)>>()
      .asFunction<void Function(Coord)>();
  Expect.throws<UnsupportedError>(() => structArg(coord.ref));

  // Struct by value return.
  final structReturn = dummyPtr
      .cast<NativeFunction<Coord Function()>>()
      .asFunction<Coord Function()>();
  Expect.throws<UnsupportedError>(() => structReturn());

  // > 12 arguments (13 int arguments).
  final thirteenArgs = dummyPtr
      .cast<
        NativeFunction<
          IntPtr Function(
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
            IntPtr,
          )
        >
      >()
      .asFunction<
        int Function(
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
        )
      >();
  Expect.throws<UnsupportedError>(
    () => thirteenArgs(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13),
  );

  calloc.free(coord);
}

void testLookupFunctionCalls() {
  final coord = calloc<Coord>();
  coord.ref.x = 1.0;
  coord.ref.y = 2.0;

  // Float return via lookupFunction.
  final floatReturn = ffiTestFunctions
      .lookupFunction<Double Function(), double Function()>("SumPlus42");
  Expect.throws<UnsupportedError>(() => floatReturn());

  // Struct by value argument via lookupFunction.
  final structArg = ffiTestFunctions
      .lookupFunction<Void Function(Coord), void Function(Coord)>("SumPlus42");
  Expect.throws<UnsupportedError>(() => structArg(coord.ref));

  // > 12 arguments via lookupFunction.
  final thirteenArgs = ffiTestFunctions
      .lookupFunction<
        IntPtr Function(
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
          IntPtr,
        ),
        int Function(
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
          int,
        )
      >("SumPlus42");
  Expect.throws<UnsupportedError>(
    () => thirteenArgs(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13),
  );

  calloc.free(coord);
}

void dummyCallback() {}
double dummyFloatCallback(double x) => x;
void dummyStructCallback(Coord c) {}
int dummy9ArgsCallback(
  int a1,
  int a2,
  int a3,
  int a4,
  int a5,
  int a6,
  int a7,
  int a8,
  int a9,
) => a1;

void testCallbacks() {
  // NativeCallable.listener (async callbacks are not supported on simulator).
  Expect.throws<UnsupportedError>(() {
    NativeCallable<Void Function()>.listener(dummyCallback);
  });

  // NativeCallable.isolateLocal with float return/argument.
  Expect.throws<UnsupportedError>(() {
    NativeCallable<Double Function(Double)>.isolateLocal(
      dummyFloatCallback,
      exceptionalReturn: 0.0,
    );
  });

  // NativeCallable.isolateLocal with struct by value argument.
  Expect.throws<UnsupportedError>(() {
    NativeCallable<Void Function(Coord)>.isolateLocal(dummyStructCallback);
  });

  // NativeCallable.isolateLocal with > 8 arguments (9 arguments).
  Expect.throws<UnsupportedError>(() {
    NativeCallable<
      IntPtr Function(
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
      )
    >.isolateLocal(dummy9ArgsCallback, exceptionalReturn: 0);
  });

  // Pointer.fromFunction with float return/argument.
  Expect.throws<UnsupportedError>(() {
    Pointer.fromFunction<Double Function(Double)>(dummyFloatCallback, 0.0);
  });

  // Pointer.fromFunction with struct by value argument.
  Expect.throws<UnsupportedError>(() {
    Pointer.fromFunction<Void Function(Coord)>(dummyStructCallback);
  });

  // Pointer.fromFunction with > 8 arguments (9 arguments).
  Expect.throws<UnsupportedError>(() {
    Pointer.fromFunction<
      IntPtr Function(
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
        IntPtr,
      )
    >(dummy9ArgsCallback, 0);
  });
}

void testErrorMessage() {
  try {
    unsupportedNativeFloatReturn();
    Expect.fail('Expected UnsupportedError to be thrown');
  } on UnsupportedError catch (e) {
    Expect.equals('Not supported on this simulator.', e.message);
    Expect.equals(
      'Unsupported operation: Not supported on this simulator.',
      e.toString(),
    );
  }
}

void main() {
  testNativeCalls();
  testAsFunctionCalls();
  testLookupFunctionCalls();
  testCallbacks();
  testErrorMessage();
  print('All simulator unsupported signature tests passed!');
}
