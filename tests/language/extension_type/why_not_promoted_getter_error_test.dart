// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that ordinary getters declared inside an extension type are not
// promotable (regardless of whether they are public or private) and that the
// implementation generates the appropriate "why not promoted" context message
// when promotion fails.

// SharedOptions=--enable-experiment=inline-class

extension type E(dynamic d) {
  int? get i1 => 0;
  //       ^^
  // [context 1] 'i1' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 3] 'i1' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 5] 'i1' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 7] 'i1' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 9] 'i1' refers to a getter so it couldn't be promoted.
  // [context 11] 'i1' refers to a getter so it couldn't be promoted.
  // [context 13] 'i1' refers to a getter so it couldn't be promoted.
  // [context 15] 'i1' refers to a getter so it couldn't be promoted.
  int? get _i2 => 0;
  //       ^^^
  // [context 2] '_i2' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 4] '_i2' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 6] '_i2' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 8] '_i2' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 10] '_i2' refers to a getter so it couldn't be promoted.
  // [context 12] '_i2' refers to a getter so it couldn't be promoted.
  // [context 14] '_i2' refers to a getter so it couldn't be promoted.
  // [context 16] '_i2' refers to a getter so it couldn't be promoted.

  void viaImplicitThis() {
    if (i1 != null) {
      i1.isEven;
      // ^^^^^^
      // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 9] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (_i2 != null) {
      _i2.isEven;
      //  ^^^^^^
      // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 10] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
  }

  void viaExplicitThis() {
    if (this.i1 != null) {
      this.i1.isEven;
      //      ^^^^^^
      // [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 11] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (this._i2 != null) {
      this._i2.isEven;
      //       ^^^^^^
      // [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 12] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
  }
}

void viaGeneralPropertyAccess(E e) {
  if ((e).i1 != null) {
    (e).i1.isEven;
    //     ^^^^^^
    // [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 13] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if ((e)._i2 != null) {
    (e)._i2.isEven;
    //      ^^^^^^
    // [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 14] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void viaPrefixedIdentifier(E e) {
  // Note: the analyzer has a special representation for property accesses of
  // the form `IDENTIFIER.IDENTIFIER`, so we test it separately.
  if (e.i1 != null) {
    e.i1.isEven;
    //   ^^^^^^
    // [analyzer 7] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 15] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (e._i2 != null) {
    e._i2.isEven;
    //    ^^^^^^
    // [analyzer 8] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 16] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
