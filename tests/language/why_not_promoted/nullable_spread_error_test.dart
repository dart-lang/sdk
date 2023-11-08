// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableSpreadError` error, for which we wish to report "why not
// promoted" context information.

class C {
  List<int>? listQuestion;
  //         ^^^^^^^^^^^^
  // [context 1] 'listQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 5] 'listQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 11] 'listQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 17] 'listQuestion' refers to a public field so it couldn't be promoted.
  // [context 21] 'listQuestion' refers to a public field so it couldn't be promoted.
  // [context 27] 'listQuestion' refers to a public field so it couldn't be promoted.
  Object? objectQuestion;
  //      ^^^^^^^^^^^^^^
  // [context 4] 'objectQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 8] 'objectQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 9] 'objectQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 10] 'objectQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 14] 'objectQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 15] 'objectQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 20] 'objectQuestion' refers to a public field so it couldn't be promoted.
  // [context 24] 'objectQuestion' refers to a public field so it couldn't be promoted.
  // [context 25] 'objectQuestion' refers to a public field so it couldn't be promoted.
  // [context 26] 'objectQuestion' refers to a public field so it couldn't be promoted.
  // [context 30] 'objectQuestion' refers to a public field so it couldn't be promoted.
  // [context 31] 'objectQuestion' refers to a public field so it couldn't be promoted.
  Set<int>? setQuestion;
  //        ^^^^^^^^^^^
  // [context 2] 'setQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 6] 'setQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 12] 'setQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 16] 'setQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 18] 'setQuestion' refers to a public field so it couldn't be promoted.
  // [context 22] 'setQuestion' refers to a public field so it couldn't be promoted.
  // [context 28] 'setQuestion' refers to a public field so it couldn't be promoted.
  // [context 32] 'setQuestion' refers to a public field so it couldn't be promoted.
  Map<int, int>? mapQuestion;
  //             ^^^^^^^^^^^
  // [context 3] 'mapQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 7] 'mapQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 13] 'mapQuestion' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 19] 'mapQuestion' refers to a public field so it couldn't be promoted.
  // [context 23] 'mapQuestion' refers to a public field so it couldn't be promoted.
  // [context 29] 'mapQuestion' refers to a public field so it couldn't be promoted.
}

list_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return [...c.listQuestion];
  //         ^^^^^^^^^^^^^^
  // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 17] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

list_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return [...c.setQuestion];
  //         ^^^^^^^^^^^^^
  // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 18] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

list_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return [...c.mapQuestion];
  //         ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ITERABLE_SPREAD
  // [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 19] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Map<int, int>?' of a spread.  Expected 'dynamic' or an Iterable.
}

list_from_object_question(C c) {
  if (c.objectQuestion is! List<int>) return;
  return [...c.objectQuestion];
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ITERABLE_SPREAD
  // [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 20] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Object?' of a spread.  Expected 'dynamic' or an Iterable.
}

set_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return {...c.listQuestion};
  //         ^^^^^^^^^^^^^^
  // [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 21] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

set_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return {...c.setQuestion};
  //         ^^^^^^^^^^^^^
  // [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 22] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

set_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return {...c.mapQuestion};
  //         ^^^^^^^^^^^^^
  // [analyzer 7] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 23] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

set_from_object_question_type_disambiguate_by_entry(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return {null, ...c.objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //               ^^^^^^^^^^^^^^^^
  // [analyzer 8] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                 ^
  // [cfe 24] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Object?' of a spread.  Expected 'dynamic' or an Iterable.
}

set_from_object_question_type_disambiguate_by_previous_spread(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return {...<int>{}, ...c.objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer 9] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                       ^
  // [cfe 25] Unexpected type 'Object?' of a map spread entry.  Expected 'dynamic' or a Map.
}

set_from_object_question_type_disambiguate_by_literal_args(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return <int>{...c.objectQuestion};
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ITERABLE_SPREAD
  // [analyzer 10] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 26] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Object?' of a spread.  Expected 'dynamic' or an Iterable.
}

map_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return {...c.listQuestion};
  //         ^^^^^^^^^^^^^^
  // [analyzer 11] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 27] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

map_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return {...c.setQuestion};
  //         ^^^^^^^^^^^^^
  // [analyzer 12] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 28] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

map_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return {...c.mapQuestion};
  //         ^^^^^^^^^^^^^
  // [analyzer 13] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 29] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

map_from_object_question_type_disambiguate_by_key_value_pair(C c) {
  if (c.objectQuestion is! Map<int, int>) return;
  return {null: null, ...c.objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer 14] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                       ^
  // [cfe 30] Unexpected type 'Object?' of a map spread entry.  Expected 'dynamic' or a Map.
}

map_from_object_question_type_disambiguate_by_previous_spread(C c) {
  if (c.objectQuestion is! Map<int, int>) return;
  return {...<int, int>{}, ...c.objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //                          ^^^^^^^^^^^^^^^^
  // [analyzer 15] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                            ^
  // [cfe 31] Unexpected type 'Object?' of a map spread entry.  Expected 'dynamic' or a Map.
}

map_from_set_question_type_disambiguate_by_literal_args(C c) {
  // Note: analyzer shows "why not promoted" information here, but CFE doesn't.
  // That's probably ok, since there are two problems here (set/map mismatch and
  // null safety); it's a matter of interpretation whether to prioritize one or
  // the other.
  if (c.setQuestion == null) return;
  return <int, int>{...c.setQuestion};
  //                   ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_MAP_SPREAD
  // [analyzer 16] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                     ^
  // [cfe 32] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Set<int>?' of a map spread entry.  Expected 'dynamic' or a Map.
}
