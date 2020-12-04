// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // Spread non-iterable or non-map.
  var _ = [...(3)]; //# 00: compile-time error
  var _ = <int, int>{...(3)}; //# 01: compile-time error
  var _ = <int>{...(3)}; //# 02: compile-time error

  // Object.
  var _ = [...([] as Object)]; //# 03: compile-time error
  var _ = <int, int>{...({} as Object)}; //# 04: compile-time error
  var _ = <int>{...([] as Object)}; //# 05: compile-time error

  // Wrong element type.
  var _ = <int>[...<String>[]]; //# 06: compile-time error
  var _ = <int, int>{...<String, int>{}}; //# 07: compile-time error
  var _ = <int, int>{...<int, String>{}}; //# 08: compile-time error
  var _ = <int>{...<String>[]}; //# 09: compile-time error

  // Downcast element.
  var _ = <int>[...<num>[1, 2]]; //# 10: compile-time error
  var _ = <int, int>{...<num, num>{1: 1, 2: 2}}; //# 11: compile-time error
  var _ = <int>{...<num>[1, 2]}; //# 12: compile-time error
}
