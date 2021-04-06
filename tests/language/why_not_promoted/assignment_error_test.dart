// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class C {
  C? operator +(int i);
  int get cProperty => 0;
}

direct_assignment(int? i, int? j) {
  if (i == null) return;
  i = j;
//^^^^^
// [context 6] Variable 'i' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
// [context 10] Variable 'i' could not be promoted due to an assignment.
  i.isEven;
//  ^^^^^^
// [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 10] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

compound_assignment(C? c, int i) {
  if (c == null) return;
  c += i;
//^^^^^^
// [context 7] Variable 'c' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
// [context 11] Variable 'c' could not be promoted due to an assignment.
  c.cProperty;
//  ^^^^^^^^^
// [analyzer 7] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 11] Property 'cProperty' cannot be accessed on 'C?' because it is potentially null.
}

via_postfix_op(C? c) {
  if (c == null) return;
  c++;
//^^^
// [context 4] Variable 'c' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
// [context 12] Variable 'c' could not be promoted due to an assignment.
  c.cProperty;
//  ^^^^^^^^^
// [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 12] Property 'cProperty' cannot be accessed on 'C?' because it is potentially null.
}

via_prefix_op(C? c) {
  if (c == null) return;
  ++c;
//^^^
// [context 9] Variable 'c' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
  //^
  // [context 13] Variable 'c' could not be promoted due to an assignment.
  c.cProperty;
//  ^^^^^^^^^
// [analyzer 9] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 13] Property 'cProperty' cannot be accessed on 'C?' because it is potentially null.
}

via_for_each_statement(int? i, List<int?> list) {
  if (i == null) return;
  for (i in list) {
  //   ^
  // [context 3] Variable 'i' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
  // [context 14] Variable 'i' could not be promoted due to an assignment.
    i.isEven;
//    ^^^^^^
// [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 14] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

via_for_each_list_element(int? i, List<int?> list) {
  if (i == null) return;
  [for (i in list) i.isEven];
  //    ^
  // [context 8] Variable 'i' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
  // [context 15] Variable 'i' could not be promoted due to an assignment.
  //                 ^^^^^^
  // [analyzer 8] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe 15] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

via_for_each_set_element(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) i.isEven});
  //     ^
  // [context 1] Variable 'i' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
  // [context 16] Variable 'i' could not be promoted due to an assignment.
  //                  ^^^^^^
  // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe 16] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

via_for_each_map_key(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) i.isEven: null});
  //     ^
  // [context 2] Variable 'i' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
  // [context 17] Variable 'i' could not be promoted due to an assignment.
  //                  ^^^^^^
  // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe 17] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

via_for_each_map_value(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) null: i.isEven});
  //     ^
  // [context 5] Variable 'i' could not be promoted due to an assignment.  See http://dart.dev/go/non-promo-write
  // [context 18] Variable 'i' could not be promoted due to an assignment.
  //                        ^^^^^^
  // [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe 18] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}
