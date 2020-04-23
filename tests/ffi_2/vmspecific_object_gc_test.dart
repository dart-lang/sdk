// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests GC of Pointer objects.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final triggerGc = ffiTestFunctions
    .lookupFunction<Void Function(), void Function()>("TriggerGC");

void main() async {
  testGC();
}

dynamic bar;

Future<void> testGC() async {
  bar = Pointer<Int8>.fromAddress(11);

  // Verify that the objects manufactured by 'fromAddress' can be scanned by the
  // GC.
  triggerGc();

  Expect.equals(11, bar.address);
}
