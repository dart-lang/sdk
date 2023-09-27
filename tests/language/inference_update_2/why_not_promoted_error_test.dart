// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the appropriate "why not promoted" context messages are shown when
// field promotion fails.

// SharedOptions=--enable-experiment=inference-update-2

class C {
  int? get _privateGetter => publicField;
  //       ^^^^^^^^^^^^^^
  // [context 1] '_privateGetter' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 4] '_privateGetter' refers to a getter so it couldn't be promoted.
  final int? publicField;
  //         ^^^^^^^^^^^
  // [context 2] 'publicField' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 5] 'publicField' refers to a public field so it couldn't be promoted.
  int? _nonFinalField;
  //   ^^^^^^^^^^^^^^
  // [context 3] '_nonFinalField' refers to a non-final field so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-final-field
  // [context 6] '_nonFinalField' refers to a non-final field so it couldn't be promoted.
  C(int? i)
      : publicField = i,
        _nonFinalField = i;
}

void notAField(C c) {
  if (c._privateGetter != null) {
    c._privateGetter.isEven;
    //               ^^^^^^
    // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 4] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void notPrivate(C c) {
  if (c.publicField != null) {
    c.publicField.isEven;
    //            ^^^^^^
    // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 5] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void notFinal(C c) {
  if (c._nonFinalField != null) {
    c._nonFinalField.isEven;
    //               ^^^^^^
    // [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 6] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
