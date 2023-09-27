// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableMethodCallError`, for which we wish to report "why not
// promoted" context information.

class C {
  int? i;
  //   ^
  // [context 3] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 4] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 5] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 6] 'i' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 10] 'i' refers to a public field so it couldn't be promoted.
  // [context 11] 'i' refers to a public field so it couldn't be promoted.
  // [context 12] 'i' refers to a public field so it couldn't be promoted.
  // [context 13] 'i' refers to a public field so it couldn't be promoted.
  void Function()? f;
  //               ^
  // [context 7] 'f' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 14] 'f' refers to a public field so it couldn't be promoted.
}

extension on int {
  get propertyOnNonNullInt => null;
  void methodOnNonNullInt() {}
}

extension on int? {
  get propertyOnNullableInt => null;
  void methodOnNullableInt() {}
}

property_get_of_variable(int? i, int? j) {
  if (i == null) return;
  i = j;
//^^^^^
// [context 1] Variable 'i' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
// [context 8] Variable 'i' could not be promoted due to an assignment.
  i.isEven;
//  ^^^^^^
// [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 8] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

extension_property_get_of_variable(int? i, int? j) {
  if (i == null) return;
  i = j;
//^^^^^
// [context 2] Variable 'i' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
// [context 9] Variable 'i' could not be promoted due to an assignment.
  i.propertyOnNullableInt;
  i.propertyOnNonNullInt;
//  ^^^^^^^^^^^^^^^^^^^^
// [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 9] Property 'propertyOnNonNullInt' cannot be accessed on 'int?' because it is potentially null.
}

property_get_of_expression(C c) {
  if (c.i == null) return;
  c.i.isEven;
//    ^^^^^^
// [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 10] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

extension_property_get_of_expression(C c) {
  if (c.i == null) return;
  c.i.propertyOnNullableInt;
  c.i.propertyOnNonNullInt;
//    ^^^^^^^^^^^^^^^^^^^^
// [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 11] Property 'propertyOnNonNullInt' cannot be accessed on 'int?' because it is potentially null.
}

method_invocation(C c) {
  if (c.i == null) return;
  c.i.abs();
//    ^^^
// [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 12] Method 'abs' cannot be called on 'int?' because it is potentially null.
}

extension_method_invocation(C c) {
  if (c.i == null) return;
  c.i.methodOnNullableInt();
  c.i.methodOnNonNullInt();
//    ^^^^^^^^^^^^^^^^^^
// [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 13] Method 'methodOnNonNullInt' cannot be called on 'int?' because it is potentially null.
}

call_invocation(C c) {
  if (c.f == null) return;
  c.f.call();
//    ^^^^
// [analyzer 7] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 14] Method 'call' cannot be called on 'void Function()?' because it is potentially null.
}
