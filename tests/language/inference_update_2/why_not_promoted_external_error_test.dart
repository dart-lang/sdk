// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the appropriate "why not promoted" context messages are shown when
// field promotion fails due to the presence of an external field.
//
// This test is in its own file since it fails under some implementations due to
// lack of a binding for the external field.

// SharedOptions=--enable-experiment=inference-update-2

class C {
  external final int? _i;
  //                  ^^
  // [context 1] '_i' refers to an external field so it couldn't be promoted.  See http://dart.dev/go/non-promo-external-field
  // [context 2] '_i' refers to an external field so it couldn't be promoted.
  // [web] Only JS interop members may be 'external'.
}

void test(C c) {
  if (c._i != null) {
    c._i.isEven;
    //   ^^^^^^
    // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 2] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
