// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/63388

import 'dart:ffi';

base mixin HeaderFields on Struct {
  @Int32()
  external int fieldA;

  external Pointer<Void> fieldB;
}

final class ExampleStruct extends Struct with HeaderFields {
  //        ^^^^^^^^^^^^^
  // [cfe] Class 'Struct with HeaderFields' cannot be extended or implemented.
  //                                          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_STRUCT_CLASS
  @Uint32()
  external int fieldC;
}

void main() {}
