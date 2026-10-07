// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

void main() {
  doDynamicLinking();
  testHandle();
  testNativeAPIs();
}

void doDynamicLinking() {
  Expect.isTrue(NativeApi.majorVersion == 2);
  Expect.isTrue(NativeApi.minorVersion >= 2);
  final initializeApi = testLibrary
      .lookupFunction<
        IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >("InitDartApiDL");
  Expect.isTrue(initializeApi(NativeApi.initializeApiDLData) == 0);
}

void testHandle() {
  final s = SomeClass(123);
  print("passObjectToC($s)");
  final result = passObjectToC(s);
  print("result = $result");
  Expect.isTrue(identical(s, result));
}

void testNativeAPIs() {
  // No need to expect here, `lookupFunction` throws an argument error if lookup fails.
  Expect.isTrue(testLibrary.providesSymbol("Dart_IsNull_DL"));
  testLibrary.lookupFunction<Bool Function(Handle), bool Function(Object)>(
    "Dart_IsNull_DL",
  );
  Expect.isTrue(NativeApi.majorVersion == 2);
  Expect.isTrue(NativeApi.minorVersion >= 4);
  Expect.isTrue(testLibrary.providesSymbol("Dart_Null_DL"));
  testLibrary.lookupFunction<Handle Function(), Object Function()>(
    "Dart_Null_DL",
  );
  Expect.isTrue(NativeApi.minorVersion >= 7);
  Expect.isTrue(testLibrary.providesSymbol("Dart_NewConcurrentNativePort_DL"));
  final newConcurrentNativePortDL = testLibrary
      .lookup<
        Pointer<
          NativeFunction<
            Int64 Function(
              Pointer<Char>,
              Pointer<NativeFunction<Dart_NativeMessageHandler>>,
              IntPtr,
            )
          >
        >
      >("Dart_NewConcurrentNativePort_DL");
  Expect.notEquals(nullptr, newConcurrentNativePortDL.value);
  final newConcurrentNativePort = newConcurrentNativePortDL.value
      .asFunction<
        int Function(
          Pointer<Char>,
          Pointer<NativeFunction<Dart_NativeMessageHandler>>,
          int,
        )
      >();
  final port = newConcurrentNativePort(
    nullptr,
    Pointer.fromFunction(_noopMessageHandler),
    4,
  );
  Expect.notEquals(0, port);
  final closeNativePortDL = testLibrary
      .lookup<Pointer<NativeFunction<Bool Function(Int64)>>>(
        "Dart_CloseNativePort_DL",
      );
  final closeNativePort = closeNativePortDL.value
      .asFunction<bool Function(int)>();
  Expect.isTrue(closeNativePort(port));
}

void _noopMessageHandler(int destPortId, Pointer<Dart_CObject> message) {}

class SomeClass {
  // We use this getter in the native api, don't tree shake it.
  @pragma("vm:entry-point")
  final int a;
  SomeClass(this.a);
}

final testLibrary = dlopenPlatformSpecific("ffi_test_functions");

final passObjectToC = testLibrary
    .lookupFunction<Handle Function(Handle), Object Function(Object)>(
      "PassObjectToCUseDynamicLinking",
    );
