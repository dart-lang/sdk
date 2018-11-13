// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=set-literals

import "dart:collection" show LinkedHashSet;

import "package:expect/expect.dart";

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
      ;
  Expect.isNull(o); // Should be unreachable with a value.

  Set<int> s //
      = {"not int"} //# 09: compile-time error
      = {4.2} //# 10: compile-time error
      = {1: 1} //# 11: compile-time error
      = {{}} //# 12: compile-time error
      = <Object>{} // Exact type. //# 13: compile-time error
      ;
  Expect.isNull(s);

  Set<Set<Object>> ss //
      = {{1: 1}} //# 14: compile-time error
      = {<int, int>{}} //# 15: compile-time error
      = {<int>{1: 1}} //# 16: compile-time error
      = const {ss} //# 17: compile-time error
      ;
  Expect.isNull(ss);

  HashSet<int> hs //
      = {} // Exact type is LinkedHashSet //# 18: compile-time error
      ;
  Expect.isNull(hs);

  LinkedHashSet<int> lhs //
      = const {} // exact type is Set //# 19: compile-time error
      ;
  Expect.isNull(lhs);

  LinkedHashSet<LinkedHashSet<int>> lhs2 //
      = {const {}} // exact type LHS<Set>. // 20: compile-time error
      ;
  Expect.isNull(lhs2);
}
