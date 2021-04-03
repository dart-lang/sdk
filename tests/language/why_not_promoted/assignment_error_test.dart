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
//^
// [context 1] Variable 'i' could not be promoted due to an assignment.
  i.isEven;
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //^
  // [cfe 1] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

compound_assignment(C? c, int i) {
  if (c == null) return;
  c += i;
//^
// [context 2] Variable 'c' could not be promoted due to an assignment.
  c.cProperty;
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //^
  // [cfe 2] Property 'cProperty' cannot be accessed on 'C?' because it is potentially null.
}

via_postfix_op(C? c) {
  if (c == null) return;
  c++;
//^
// [context 3] Variable 'c' could not be promoted due to an assignment.
  c.cProperty;
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //^
  // [cfe 3] Property 'cProperty' cannot be accessed on 'C?' because it is potentially null.
}

via_prefix_op(C? c) {
  if (c == null) return;
  ++c;
  //^
  // [context 4] Variable 'c' could not be promoted due to an assignment.
  c.cProperty;
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //^
  // [cfe 4] Property 'cProperty' cannot be accessed on 'C?' because it is potentially null.
}

via_for_each_statement(int? i, List<int?> list) {
  if (i == null) return;
  for (i in list) {
  //   ^
  // [context 5] Variable 'i' could not be promoted due to an assignment.
    i.isEven;
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    //^
    // [cfe 5] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

via_for_each_list_element(int? i, List<int?> list) {
  if (i == null) return;
  [for (i in list) i.isEven];
  //    ^
  // [context 6] Variable 'i' could not be promoted due to an assignment.
  //                 ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                 ^
  // [cfe 6] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

via_for_each_set_element(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) i.isEven});
  //     ^
  // [context 7] Variable 'i' could not be promoted due to an assignment.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                  ^
  // [cfe 7] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

via_for_each_map_key(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) i.isEven: null});
  //     ^
  // [context 8] Variable 'i' could not be promoted due to an assignment.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                  ^
  // [cfe 8] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}

via_for_each_map_value(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) null: i.isEven});
  //     ^
  // [context 9] Variable 'i' could not be promoted due to an assignment.
  //                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                        ^
  // [cfe 9] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
}
