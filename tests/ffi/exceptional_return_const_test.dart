// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests passing non-trivial const expressions to exceptionalReturn.
//
// VMOptions=
// VMOptions=--stacktrace-every=100
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

typedef NativeCallTwoIntFunction = Int32 Function(Pointer, Int32, Int32);
typedef NativeCallTwoIntFunctionFn = int Function(Pointer, int, int);
final NativeCallTwoIntFunctionFn callNative = ffiTestFunctions
    .lookupFunction<NativeCallTwoIntFunction, NativeCallTwoIntFunctionFn>(
      'CallTwoIntFunction',
      isLeaf: false,
    );
int call(Pointer callback) => callNative(callback, 0, 0);

typedef FnType = Int32 Function(Int32, Int32);
int fn(int x, int y) => throw Exception();

class SomeClass {
  static const constMember = 789;
}

void main() {
  Expect.equals(call(Pointer.fromFunction<FnType>(fn, 123)), 123);
  Expect.equals(
    call(
      (NativeCallable<FnType>.isolateLocal(
        fn,
        exceptionalReturn: 123,
      )..keepIsolateAlive = false).nativeFunction,
    ),
    123,
  );

  Expect.equals(call(Pointer.fromFunction<FnType>(fn, 123 + 456)), 579);
  Expect.equals(
    call(
      (NativeCallable<FnType>.isolateLocal(
        fn,
        exceptionalReturn: 123 + 456,
      )..keepIsolateAlive = false).nativeFunction,
    ),
    579,
  );

  Expect.equals(call(Pointer.fromFunction<FnType>(fn, -123)), -123);
  Expect.equals(
    call(
      (NativeCallable<FnType>.isolateLocal(
        fn,
        exceptionalReturn: -123,
      )..keepIsolateAlive = false).nativeFunction,
    ),
    -123,
  );

  Expect.equals(
    call(Pointer.fromFunction<FnType>(fn, SomeClass.constMember)),
    789,
  );
  Expect.equals(
    call(
      (NativeCallable<FnType>.isolateLocal(
        fn,
        exceptionalReturn: SomeClass.constMember,
      )..keepIsolateAlive = false).nativeFunction,
    ),
    789,
  );

  const someConst = 123;
  Expect.equals(call(Pointer.fromFunction<FnType>(fn, someConst)), 123);
  Expect.equals(
    call(
      (NativeCallable<FnType>.isolateLocal(
        fn,
        exceptionalReturn: someConst,
      )..keepIsolateAlive = false).nativeFunction,
    ),
    123,
  );

  print('All tests completed :)');
}
