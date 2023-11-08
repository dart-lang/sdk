// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `ForInLoopTypeNotIterableNullability` or
// `ForInLoopTypeNotIterablePartNullability` errors, for which we wish to report
// "why not promoted" context information.

class C1 {
  List<int>? bad;
  //         ^^^
  // [context 1] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 2] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 3] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 4] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 5] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 6] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 7] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 8] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 9] 'bad' refers to a public field so it couldn't be promoted.
  // [context 10] 'bad' refers to a public field so it couldn't be promoted.
  // [context 11] 'bad' refers to a public field so it couldn't be promoted.
  // [context 12] 'bad' refers to a public field so it couldn't be promoted.
  // [context 13] 'bad' refers to a public field so it couldn't be promoted.
  // [context 14] 'bad' refers to a public field so it couldn't be promoted.
  // [context 15] 'bad' refers to a public field so it couldn't be promoted.
  // [context 16] 'bad' refers to a public field so it couldn't be promoted.
}

forStatement(C1 c) {
  if (c.bad == null) return;
  for (var x in c.bad) {}
  //            ^^^^^
  // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //              ^
  // [cfe 9] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInList(C1 c) {
  if (c.bad == null) return;
  [for (var x in c.bad) null];
  //             ^^^^^
  // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //               ^
  // [cfe 10] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInSet(C1 c) {
  if (c.bad == null) return;
  <dynamic>{for (var x in c.bad) null};
  //                      ^^^^^
  // [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                        ^
  // [cfe 11] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInMap(C1 c) {
  if (c.bad == null) return;
  <dynamic, dynamic>{for (var x in c.bad) null: null};
  //                               ^^^^^
  // [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                                 ^
  // [cfe 12] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInAmbiguousSet_resolvableDuringParsing(C1 c) {
  if (c.bad == null) return;
  ({for (var x in c.bad) null});
  //              ^^^^^
  // [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 13] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInAmbiguousMap_resolvableDuringParsing(C1 c) {
  if (c.bad == null) return;
  ({for (var x in c.bad) null: null});
  //              ^^^^^
  // [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 14] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInAmbiguousSet_notResolvableDuringParsing(C1 c, List list) {
  if (c.bad == null) return;
  ({for (var x in c.bad) ...list});
  //              ^^^^^
  // [analyzer 7] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 15] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}

forElementInAmbiguousMap_notResolvableDuringParsing(C1 c, Map map) {
  if (c.bad == null) return;
  ({for (var x in c.bad) ...map});
  //              ^^^^^
  // [analyzer 8] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                ^
  // [cfe 16] The type 'List<int>?' used in the 'for' loop must implement 'Iterable<dynamic>' because 'List<int>?' is nullable and 'Iterable<dynamic>' isn't.
}
