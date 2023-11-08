// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int? i;
  //   ^
  // [context 1] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 2] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 3] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 4] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 5] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 6] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 7] 'i' refers to a public field so it couldn't be promoted.
  // [context 8] 'i' refers to a public field so it couldn't be promoted.
  // [context 9] 'i' refers to a public field so it couldn't be promoted.
  // [context 10] 'i' refers to a public field so it couldn't be promoted.
  // [context 11] 'i' refers to a public field so it couldn't be promoted.
  // [context 12] 'i' refers to a public field so it couldn't be promoted.
  int? j;

  get_field_via_explicit_this() {
    if (this.i == null) return;
    this.i.isEven;
//         ^^^^^^
// [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 7] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }

  get_field_via_explicit_this_parenthesized() {
    if ((this).i == null) return;
    (this).i.isEven;
//           ^^^^^^
// [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 8] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }

  get_field_by_implicit_this() {
    if (i == null) return;
    i.isEven;
//    ^^^^^^
// [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 9] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

class D extends C {
  get_field_via_explicit_super() {
    if (super.i == null) return;
    super.i.isEven;
//          ^^^^^^
// [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 10] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }

  get_field_by_implicit_super() {
    if (i == null) return;
    i.isEven;
//    ^^^^^^
// [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 11] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

get_field_via_prefixed_identifier(C c) {
  if (c.i == null) return;
  c.i.isEven;
//    ^^^^^^
// [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 12] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

get_field_via_prefixed_identifier_mismatched_target(C c1, C c2) {
  // Note: no context on this error because the property the user is attempting
  // to promote is on c1, but the property the user is accessing is on c2.
  if (c1.i == null) return;
  c2.i.isEven;
//     ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

get_field_via_prefixed_identifier_mismatched_property(C c) {
  // Note: no context on this error because the property the user is attempting
  // to promote is C.i, but the property the user is accessing is C.j.
  if (c.i == null) return;
  c.j.isEven;
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}
