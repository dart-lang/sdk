// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

final nativeLib = dlopenPlatformSpecific("ffi_test_functions");

void main() {
  final isNull = nativeLib
      .lookupFunction<Bool Function(Handle), bool Function(Object?)>('IsNull');
  Expect.equals(isNull(null), true);
  Expect.equals(isNull(Object()), false);
}
