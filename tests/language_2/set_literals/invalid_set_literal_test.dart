// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=set-literals

import "dart:collection" show LinkedHashSet;

import "package:expect/expect.dart";

const Object d = 3.5;

void main() {
   var o //
      = <int>{1: 1} //# 01: compile-time error
      = <int, int, int>{} //# 02: compile-time error
      = <int, int, int>{1} //# 03: compile-time error
      = <int, int>{1} //# 04: compile-time error
      = const <int, int, int>{} //# 05: compile-time error
      = const <int, int, int>{1} //# 06: compile-time error
      = const <int, int>{1} //# 07: compile-time error
      = const {Duration(seconds: 0)} // Overrides ==. //# 08: compile-time error
      = {4.2} // Overrides ==. //# 09: compile-time error
      = {d} // Overrides ==. //# 10: compile-time error
      = {,} //# 11: compile-time error
      = {1,,} //# 12: compile-time error
      = {1,,1} //# 13: compile-time error
      ;
  Expect.isNull(o); // Should be unreachable with a value.

  Set<int> s //
      = {"not int"} //# 14: compile-time error
      = {4.2} //# 15: compile-time error
      = {1: 1} //# 16: compile-time error
      = {{}} //# 17: compile-time error
      = <Object>{} // Exact type. //# 18: compile-time error
      ;
  Expect.isNull(s);

  Set<Set<Object>> ss //
      = {{1: 1}} //# 19: compile-time error
      = {<int, int>{}} //# 20: compile-time error
      = {<int>{1: 1}} //# 21: compile-time error
      = const {ss} //# 22: compile-time error
      ;
  Expect.isNull(ss);

  HashSet<int> hs //
      = {} // Exact type is LinkedHashSet //# 23: compile-time error
      ;
  Expect.isNull(hs);

  LinkedHashSet<int> lhs //
      = const {} // exact type is Set //# 24: compile-time error
      ;
  Expect.isNull(lhs);

  LinkedHashSet<LinkedHashSet<int>> lhs2 //
      = {const {}} // exact type LHS<Set>. //# 25: compile-time error
      ;
  Expect.isNull(lhs2);

  <T>(x) {
    // Type constants are allowed, type variables are not.
    var o //
        = const {T} //# 26: compile-time error
        = const {x} //# 27: compile-time error
        ;
    Expect.isNull(o);
  }<int>(42);
}
