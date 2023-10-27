// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that when the representation variable of an extension type is not
// promotable, the implementation generates the appropriate "why not promoted"
// context message.

// SharedOptions=--enable-experiment=inline-class

extension type E(int? i) {
//                    ^
// [context 1] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
// [context 2] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
// [context 3] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
// [context 4] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
// [context 5] 'i' refers to a public field so it couldn't be promoted.
// [context 6] 'i' refers to a public field so it couldn't be promoted.
// [context 7] 'i' refers to a public field so it couldn't be promoted.
// [context 8] 'i' refers to a public field so it couldn't be promoted.
  void viaImplicitThis() {
    if (i != null) {
      i.isEven;
      //^^^^^^
      // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 5] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
  }

  void viaExplicitThis() {
    if (this.i != null) {
      i.isEven;
      //^^^^^^
      // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 6] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
  }
}

void viaGeneralPropertyAccess(E e) {
  if ((e).i != null) {
    (e).i.isEven;
    //    ^^^^^^
    // [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 7] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void viaPrefixedIdentifier(E e) {
  // Note: the analyzer has a special representation for property accesses of
  // the form `IDENTIFIER.IDENTIFIER`, so we test this form separately.
  if (e.i != null) {
    e.i.isEven;
    //  ^^^^^^
    // [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 8] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
