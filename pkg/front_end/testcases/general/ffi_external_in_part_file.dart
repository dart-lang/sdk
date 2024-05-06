// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

part "ffi_external_in_part_lib.dart";

// We don't actually want to try to run anything.
void notMain() {
  print(returnStruct1ByteIntNative(-1));
}

final class Struct1ByteInt extends Struct {
  @Int8()
  external int a0;
}
