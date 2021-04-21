// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test programing for testing that optimizations do wrongly assume loads
// from and stores to C memory are not aliased.
// 
// SharedOptions=--enable-experiment=no-non-nullable
// @dart=2.12

import "dart:ffi";
import "package:expect/expect.dart";

class MyStruct extends Struct {
  @Array.multi([-1])  // no error
  external Array<Uint8> a0;
}

void main() {
  var getException = false;
  try {
      MyStruct? ms = null;
  } on Error {
      getException = true;
  }
  Expect.equals(getException, true);
}