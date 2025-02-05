// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

void main() {
  testClose();
  testUnclosable();
}

void testClose() {
  final lib = dlopenPlatformSpecific("ffi_test_functions");
  lib.lookup('ReturnMaxUint8');

  lib.close();
  Expect.throwsStateError(
    () => lib.lookup('ReturnMaxUint8'),
    'Illegal lookup in closed library',
  );
  lib.close(); // Duplicate close should not crash.
}

void testUnclosable() {
  final proc = DynamicLibrary.process();
  final exec = DynamicLibrary.executable();

  Expect.throwsStateError(proc.close);
  Expect.throwsStateError(exec.close);
}
