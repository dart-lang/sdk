// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the appropriate "why not promoted" context messages are shown when
// field promotion fails due to the field being public.
//
// Both fields in the same library and in other libraries are exercised.

import 'why_not_promoted_public_lib.dart';

class ClassInSameLibrary {
  final int? i;
  //         ^
  // [context 1] 'i' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 2] 'i' refers to a public property so it couldn't be promoted.
  ClassInSameLibrary(this.i);
}

void testSameLibrary(ClassInSameLibrary c) {
  if (c.i != null) {
    c.i.isEven;
    //  ^^^^^^
    // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 2] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void testOtherLibrary(ClassInOtherLibrary c) {
  if (c.i != null) {
    c.i.isEven;
    //  ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
