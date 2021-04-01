// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableSpreadError` error, for which we wish to report "why not
// promoted" context information.

class C {
  List<int>? listQuestion;
  //         ^
  // [context 1] 'listQuestion' refers to a property so it couldn't be promoted.
  // [context 5] 'listQuestion' refers to a property so it couldn't be promoted.
  // [context 11] 'listQuestion' refers to a property so it couldn't be promoted.
  Object? objectQuestion;
  //      ^
  // [context 4] 'objectQuestion' refers to a property so it couldn't be promoted.
  // [context 8] 'objectQuestion' refers to a property so it couldn't be promoted.
  // [context 9] 'objectQuestion' refers to a property so it couldn't be promoted.
  // [context 10] 'objectQuestion' refers to a property so it couldn't be promoted.
  // [context 14] 'objectQuestion' refers to a property so it couldn't be promoted.
  // [context 15] 'objectQuestion' refers to a property so it couldn't be promoted.
  Set<int>? setQuestion;
  //        ^
  // [context 2] 'setQuestion' refers to a property so it couldn't be promoted.
  // [context 6] 'setQuestion' refers to a property so it couldn't be promoted.
  // [context 12] 'setQuestion' refers to a property so it couldn't be promoted.
  // [context 16] 'setQuestion' refers to a property so it couldn't be promoted.
  Map<int, int>? mapQuestion;
  //             ^
  // [context 3] 'mapQuestion' refers to a property so it couldn't be promoted.
  // [context 7] 'mapQuestion' refers to a property so it couldn't be promoted.
  // [context 13] 'mapQuestion' refers to a property so it couldn't be promoted.
}

list_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return [...c.listQuestion];
  //         ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 1] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

list_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return [...c.setQuestion];
  //         ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 2] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

list_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return [...c.mapQuestion];
  //         ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ITERABLE_SPREAD
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 3] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Map<int, int>?' of a spread.  Expected 'dynamic' or an Iterable.
}

list_from_object_question(C c) {
  if (c.objectQuestion is! List<int>) return;
  return [...c.objectQuestion];
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ITERABLE_SPREAD
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 4] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Object?' of a spread.  Expected 'dynamic' or an Iterable.
}

set_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return {...c.listQuestion};
  //         ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 5] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

set_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return {...c.setQuestion};
  //         ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 6] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

set_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return {...c.mapQuestion};
  //         ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 7] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

set_from_object_question_type_disambiguate_by_entry(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return {null, ...c.objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //               ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                 ^
  // [cfe 8] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Object?' of a spread.  Expected 'dynamic' or an Iterable.
}

set_from_object_question_type_disambiguate_by_previous_spread(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return {...<int>{}, ...c.objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                       ^
  // [cfe 9] Unexpected type 'Object?' of a map spread entry.  Expected 'dynamic' or a Map.
}

set_from_object_question_type_disambiguate_by_literal_args(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return <int>{...c.objectQuestion};
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ITERABLE_SPREAD
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 10] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Object?' of a spread.  Expected 'dynamic' or an Iterable.
}

map_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return {...c.listQuestion};
  //         ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 11] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

map_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return {...c.setQuestion};
  //         ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 12] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

map_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return {...c.mapQuestion};
  //         ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //           ^
  // [cfe 13] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
}

map_from_object_question_type_disambiguate_by_key_value_pair(C c) {
  if (c.objectQuestion is! Map<int, int>) return;
  return {null: null, ...c.objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                       ^
  // [cfe 14] Unexpected type 'Object?' of a map spread entry.  Expected 'dynamic' or a Map.
}

map_from_object_question_type_disambiguate_by_previous_spread(C c) {
  if (c.objectQuestion is! Map<int, int>) return;
  return {...<int, int>{}, ...c.objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                            ^
  // [cfe 15] Unexpected type 'Object?' of a map spread entry.  Expected 'dynamic' or a Map.
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
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                     ^
  // [cfe 16] An expression whose value can be 'null' must be null-checked before it can be dereferenced.
  // [cfe] Unexpected type 'Set<int>?' of a map spread entry.  Expected 'dynamic' or a Map.
}
