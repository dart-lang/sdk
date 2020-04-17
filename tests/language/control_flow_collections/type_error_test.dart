// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // Non-Boolean if condition.
  var _ = <int>[if (1) 2]; //# 00: compile-time error
  var _ = <int, int>{if (1) 2: 2}; //# 01: compile-time error
  var _ = <int>{if (1) 2}; //# 02: compile-time error

  // Wrong then element type.
  var _ = <int>[if (true) "s"]; //# 04: compile-time error
  var _ = <int, int>{if (true) "s": 1}; //# 05: compile-time error
  var _ = <int, int>{if (true) 1: "s"}; //# 06: compile-time error
  var _ = <int>{if (true) "s"}; //# 07: compile-time error

  // Wrong else element type.
  var _ = <int>[if (false) 1 else "s"]; //# 08: compile-time error
  var _ = <int, int>{if (false) 1: 1 else "s": 2}; //# 09: compile-time error
  var _ = <int, int>{if (false) 1: 1 else 2: "s"}; //# 10: compile-time error
  var _ = <int>{if (false) 1 else "s"}; //# 11: compile-time error

  // Non-Boolean for condition.
  var _ = <int>[for (; 1;) 2]; //# 12: compile-time error
  var _ = <int, int>{for (; 1;) 2: 2}; //# 13: compile-time error
  var _ = <int>{for (; 1;) 2}; //# 14: compile-time error

  // Wrong for-in element type.
  List<String> s = ["s"];
  var _ = <int>[for (int i in s) 1]; //# 15: compile-time error
  var _ = <int, int>{for (int i in s) 1: 1}; //# 16: compile-time error
  var _ = <int>{for (int i in s) 1}; //# 17: compile-time error

  // Wrong for declaration element type.
  var _ = <int>[for (int i = "s"; false;) 1]; //# 18: compile-time error
  var _ = <int, int>{for (int i = "s"; false;) 1: 1}; //# 19: compile-time error
  var _ = <int>{for (int i = "s"; false;) 1}; //# 20: compile-time error

  // Wrong for body element type.
  var _ = <int>[for (; false;) "s"]; //# 21: compile-time error
  var _ = <int, int>{for (; false;) "s": 1}; //# 22: compile-time error
  var _ = <int, int>{for (; false;) 1: "s"}; //# 23: compile-time error
  var _ = <int>{for (; false;) "s"}; //# 24: compile-time error

  // Non-iterable sequence type.
  int nonIterable = 3;
  var _ = <int>[for (int i in nonIterable) 1]; //# 25: compile-time error
  var _ = <int, int>{for (int i in nonIterable) 1: 1}; //# 26: compile-time error
  var _ = <int>{for (int i in nonIterable) 1}; //# 27: compile-time error
}
