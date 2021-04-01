// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `ForInLoopTypeNotIterableNullability` or
// `ForInLoopTypeNotIterablePartNullability` errors, for which we wish to report
// "why not promoted" context information.

class C1 {
  List<int>? bad;
  //         ^
  // [context 1] 'bad' refers to a property so it couldn't be promoted.
  // [context 2] 'bad' refers to a property so it couldn't be promoted.
  // [context 3] 'bad' refers to a property so it couldn't be promoted.
  // [context 4] 'bad' refers to a property so it couldn't be promoted.
  // [context 5] 'bad' refers to a property so it couldn't be promoted.
  // [context 6] 'bad' refers to a property so it couldn't be promoted.
  // [context 7] 'bad' refers to a property so it couldn't be promoted.
  // [context 8] 'bad' refers to a property so it couldn't be promoted.
}

forStatement(C1 c) {
  if (c.bad == null) return;
  for (var x in c.bad) {}
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //              ^
  // [cfe 1] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInList(C1 c) {
  if (c.bad == null) return;
  [for (var x in c.bad) null];
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //               ^
  // [cfe 2] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInSet(C1 c) {
  if (c.bad == null) return;
  <dynamic>{for (var x in c.bad) null};
  //                      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                        ^
  // [cfe 3] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInMap(C1 c) {
  if (c.bad == null) return;
  <dynamic, dynamic>{for (var x in c.bad) null: null};
  //                               ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                                 ^
  // [cfe 4] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInAmbiguousSet_resolvableDuringParsing(C1 c) {
  if (c.bad == null) return;
  ({for (var x in c.bad) null});
  //              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 5] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInAmbiguousMap_resolvableDuringParsing(C1 c) {
  if (c.bad == null) return;
  ({for (var x in c.bad) null: null});
  //              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 6] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInAmbiguousSet_notResolvableDuringParsing(C1 c, List list) {
  if (c.bad == null) return;
  ({for (var x in c.bad) ...list});
  //              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 7] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInAmbiguousMap_notResolvableDuringParsing(C1 c, Map map) {
  if (c.bad == null) return;
  ({for (var x in c.bad) ...map});
  //              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 8] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}
