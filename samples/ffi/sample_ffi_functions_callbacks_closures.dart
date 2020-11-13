// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

void main() {
  print('start main');

  doDynamicLinking();

  int counter = 0;
  void closure() {
    counter++;
  }

  // C holds on to this closure through a `Dart_PersistenHandle`.
  registerClosureCallback(closure);

  // Some time later this closure can be invoked.
  invokeClosureCallback();
  Expect.equals(1, counter);

  // When C is done it needs to stop holding on to the closure such that the
  // Dart GC can collect the closure.
  releaseClosureCallback();

  print('end main');
}

final testLibrary = dlopenPlatformSpecific("ffi_test_functions");

final registerClosureCallback =
    testLibrary.lookupFunction<Void Function(Handle), void Function(Object)>(
        "RegisterClosureCallback");

final invokeClosureCallback = testLibrary
    .lookupFunction<Void Function(), void Function()>("InvokeClosureCallback");

final releaseClosureCallback = testLibrary
    .lookupFunction<Void Function(), void Function()>("ReleaseClosureCallback");

void doClosureCallback(Object callback) {
  final callback_as_function = callback as void Function();
  callback_as_function();
}

final closureCallbackPointer =
    Pointer.fromFunction<Void Function(Handle)>(doClosureCallback);

void doDynamicLinking() {
  Expect.isTrue(NativeApi.majorVersion == 2);
  Expect.isTrue(NativeApi.minorVersion >= 0);
  final initializeApi = testLibrary.lookupFunction<
      IntPtr Function(Pointer<Void>),
      int Function(Pointer<Void>)>("InitDartApiDL");
  Expect.isTrue(initializeApi(NativeApi.initializeApiDLData) == 0);

  final registerClosureCallback = testLibrary.lookupFunction<
      Void Function(Pointer),
      void Function(Pointer)>("RegisterClosureCallbackFP");
  registerClosureCallback(closureCallbackPointer);
}
