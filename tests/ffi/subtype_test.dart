// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi Pointer subtypes.
//
// SharedObjects=ffi_test_functions
// VMOptions=--verbose-gc

library FfiTest;

import 'dart:ffi' as ffi;

import "package:expect/expect.dart";

import 'cstring.dart';
import 'dylib_utils.dart';

ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

final triggerGc = ffiTestFunctions
    .lookupFunction<ffi.Void Function(), void Function()>("TriggerGC");

void main() async {
  testAllocate();
  testSizeOf();
  testGC();
}

dynamic bar;

void testAllocate() {
  CString cs = CString.toUtf8("hello world!");
  Expect.equals("hello world!", cs.fromUtf8());
  cs.free();
}

Future<void> testGC() async {
  bar = ffi.fromAddress<CString>(11);
  // Verify that the objects manufactured by 'fromAddress' can be scanned by the
  // GC.
  triggerGc();
}

void testSizeOf() {
  Expect.equals(true, 4 == ffi.sizeOf<CString>() || 8 == ffi.sizeOf<CString>());
}
