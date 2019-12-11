// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

class EVP_MD extends Struct {}

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final EVP_sha1 = ffiTestFunctions.lookupFunction<Pointer<EVP_MD> Function(),
    Pointer<EVP_MD> Function()>('LargePointer');

main() {
  int result = EVP_sha1().address;
  // On 32 bit only the lowest 32 bits are returned, so only test those.
  result &= 0x00000000FFFFFFFF;
  Expect.equals(0x0000000082000000, result);
}
