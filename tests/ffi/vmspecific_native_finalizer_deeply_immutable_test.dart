// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';
import 'ffi_test_helpers.dart';

void main() {
  testAttachDeeplyImmutableThrows();
}

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

@pragma('vm:deeply-immutable')
final class MyFinalizable implements Finalizable {}

void testAttachDeeplyImmutableThrows() {
  final myFinalizable = MyFinalizable();

  Expect.throwsUnsupportedError(
    () => setTokenFinalizer.attach(myFinalizable, nullptr.cast()),
  );
}
