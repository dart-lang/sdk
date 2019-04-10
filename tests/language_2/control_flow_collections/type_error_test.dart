// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=control-flow-collections,constant-update-2018

void main() {
  // Non-Boolean if condition.
  var _ = <int>[if (1) 2]; //# 00: compile-time error
  var _ = <int, int>{if (1) 2: 2}; //# 01: compile-time error
  var _ = <int>{if (1) 2}; //# 02: compile-time error

  // Wrong then element type.
  var _ = <int>[if (true) "s"]; //# 06: compile-time error
  var _ = <int, int>{if (true) "s": 1}; //# 07: compile-time error
  var _ = <int, int>{if (true) 1: "s"}; //# 08: compile-time error
  var _ = <int>{if (true) "s"}; //# 09: compile-time error

  // Wrong else element type.
  var _ = <int>[if (false) 1 else "s"]; //# 10: compile-time error
  var _ = <int, int>{if (false) 1: 1 else "s": 2}; //# 11: compile-time error
  var _ = <int, int>{if (false) 1: 1 else 2: "s"}; //# 12: compile-time error
  var _ = <int>{if (false) 1 else "s"}; //# 13: compile-time error

  // Non-Boolean for condition.
  var _ = <int>[for (; 1;) 2]; //# 14: compile-time error
  var _ = <int, int>{for (; 1;) 2: 2}; //# 15: compile-time error
  var _ = <int>{for (; 1;) 2}; //# 16: compile-time error

  // Wrong for-in element type.
  List<String> s = ["s"];
  var _ = <int>[for (int i in s) 1]; //# 20: compile-time error
  var _ = <int, int>{for (int i in s) 1: 1}; //# 21: compile-time error
  var _ = <int>{for (int i in s) 1}; //# 22: compile-time error

  // Wrong for declaration element type.
  var _ = <int>[for (int i = "s"; false;) 1]; //# 23: compile-time error
  var _ = <int, int>{for (int i = "s"; false;) 1: 1}; //# 24: compile-time error
  var _ = <int>{for (int i = "s"; false;) 1}; //# 25: compile-time error

  // Wrong for body element type.
  var _ = <int>[for (; false;) "s"]; //# 26: compile-time error
  var _ = <int, int>{for (; false;) "s": 1}; //# 27: compile-time error
  var _ = <int, int>{for (; false;) 1: "s"}; //# 28: compile-time error
  var _ = <int>{for (; false;) "s"}; //# 29: compile-time error

  // Non-iterable sequence type.
  int nonIterable = 3;
  var _ = <int>[for (int i in nonIterable) 1]; //# 30: compile-time error
  var _ = <int, int>{for (int i in nonIterable) 1: 1}; //# 31: compile-time error
  var _ = <int>{for (int i in nonIterable) 1}; //# 32: compile-time error
}
