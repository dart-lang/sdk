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
}

void doDynamicLinking() {
  Expect.isTrue(NativeApi.majorVersion == 2);
  Expect.isTrue(NativeApi.minorVersion >= 0);
  final initializeApi = testLibrary.lookupFunction<
      IntPtr Function(Pointer<Void>),
      int Function(Pointer<Void>)>("InitDartApiDL");
  Expect.isTrue(initializeApi(NativeApi.initializeApiDLData) == 0);
}

void testHandle() {
  final s = SomeClass(123);
  print("passObjectToC($s)");
  final result = passObjectToC(s);
  print("result = $result");
  Expect.isTrue(identical(s, result));
}

class SomeClass {
  // We use this getter in the native api, don't tree shake it.
  @pragma("vm:entry-point")
  final int a;
  SomeClass(this.a);
}

final testLibrary = dlopenPlatformSpecific("ffi_test_functions");

final passObjectToC = testLibrary.lookupFunction<Handle Function(Handle),
    Object Function(Object)>("PassObjectToCUseDynamicLinking");
