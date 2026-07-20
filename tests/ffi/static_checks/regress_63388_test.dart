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

// An unconstrained mixin cannot be applied to a struct either: the mixin
// application class is itself treated as a struct, so the CFE rejects it.
mixin ExtraGetters {
  int get extra => 4;
}

final class GetterStruct extends Struct with ExtraGetters {
  //        ^^^^^^^^^^^^
  // [cfe] Class 'Struct with ExtraGetters' cannot be extended or implemented.
  // [cfe] Struct 'Struct with ExtraGetters' is empty. Empty structs and unions are undefined behavior.
  @Int32()
  external int fieldD;
}

// Sharing members through a plain interface is allowed.
abstract interface class HasChecksum {
  int get checksum;
}

final class ChecksumStruct extends Struct implements HasChecksum {
  @Int32()
  external int payload;

  @override
  int get checksum => payload ^ 0xFF;
}

void main() {}
