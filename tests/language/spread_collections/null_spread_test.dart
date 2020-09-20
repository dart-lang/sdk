// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the inferred element type, key type, and value type of a spread
// element of the form `...?e` where `e` has type `Null` or a potentially
// nullable subtype thereof is `Never`; and the element, key, and value types
// are also `Never` for `...e` where the type of `e` is a subtype of `Never`.

import 'package:expect/expect.dart';

Function f = uncalled; // Do not optimize away `uncalled`.
Never myNever = throw 1;

void uncalled<X extends Null>(X x) {
  // Test empty collection, involving only type `Never`.
  var l1 = [...?x];
  List<Never> l1b = l1;
  var l2 = [...myNever];
  List<Never> l2b = l2;
  var l3 = [...?myNever];
  //        ^^^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //            ^
  // [cfe] Operand of null-aware operation '...?' has type 'Never' which excludes null.
  List<Never> l3b = l3;
  var s1 = {...?x, if (false) throw 1};
  Set<Never> s1b = s1;
  var s2 = {...myNever, if (false) throw 1};
  Set<Never> s2b = s2;
  var s3 = {...?myNever, if (false) throw 1};
  //        ^^^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //            ^
  // [cfe] Operand of null-aware operation '...?' has type 'Never' which excludes null.
  Set<Never> s3b = s3;
  var m1 = {...?x, if (false) throw 1: throw 1};
  Map<Never, Never> m1b = m1;
  var m2 = {...myNever, if (false) throw 1: throw 1};
  Map<Never, Never> m2b = m2;
  var m3 = {...?myNever, if (false) throw 1: throw 1};
  //        ^^^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //            ^
  // [cfe] Operand of null-aware operation '...?' has type 'Never' which excludes null.
  Map<Never, Never> m3b = m3;

  // Test non-empty collection of `Never` and `int`.
  var li1 = [...?x, 1];
  List<int> li1b = li1;
  var li2 = [...myNever, 1];
  List<int> li2b = li2;
  var li3 = [...?myNever, 1];
  //         ^^^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //             ^
  // [cfe] Operand of null-aware operation '...?' has type 'Never' which excludes null.
  List<int> li3b = li3;
  var si1 = {1, ...?x};
  Set<int> si1b = si1;
  var si2 = {1, ...myNever};
  Set<int> si2b = si2;
  var si3 = {1, ...?myNever};
  //            ^^^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //                ^
  // [cfe] Operand of null-aware operation '...?' has type 'Never' which excludes null.
  Set<int> si3b = si3;
  var mi1 = {1: 1, ...?x};
  Map<int, int> mi1b = mi1;
  var mi2 = {1: 1, ...myNever};
  Map<int, int> mi2b = mi2;
  var mi3 = {1: 1, ...?myNever};
  //               ^^^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //                   ^
  // [cfe] Operand of null-aware operation '...?' has type 'Never' which excludes null.
  Map<int, int> mi3b = mi3;
}

void main() {
  Null myNull = null;

  // Test empty collection, involving only type `Never`.
  var l1 = [...?null];
  List<Never> l1b = l1;
  var l2 = [...?myNull];
  List<Never> l2b = l2;
  var s1 = {...?null, if (false) throw 1};
  Set<Never> s1b = s1;
  var s2 = {if (false) throw 1, ...?myNull};
  Set<Never> s2b = s2;
  var m1 = {...?null, if (false) throw 1: throw 1};
  Map<Never, Never> m1b = m1;
  var m2 = {if (false) throw 1: throw 1, ...?myNull};
  Map<Never, Never> m2b = m2;

  // Test non-empty collection of `Never` and `int`.
  var li1 = [...?null, 1];
  List<int> li1b = li1;
  var li2 = [1, ...?myNull];
  List<int> li2b = li2;
  var si1 = {1, ...?null};
  Set<int> si1b = si1;
  var si2 = {...?myNull, 1};
  Set<int> si2b = si2;
  var mi1 = {1: 1, ...?null};
  Map<int, int> mi1b = mi1;
  var mi2 = {...?myNull, 1: 1};
  Map<int, int> mi2b = mi2;
}
