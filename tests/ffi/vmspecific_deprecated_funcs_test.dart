// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:io';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");
final initializeApi = ffiTestFunctions.lookupFunction<
    IntPtr Function(Pointer<Void>),
    int Function(Pointer<Void>)>("InitDartApiDL");

main() {
  initializeApi(NativeApi.initializeApiDLData);
  final isDeprecated =
      ffiTestFunctions.lookupFunction<Void Function(), void Function()>(
          "TestDeprecatedSymbols");
  isDeprecated();
}
