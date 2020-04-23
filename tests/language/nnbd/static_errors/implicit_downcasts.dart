// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error to do what was once allowed as an "implicit
// downcast."
main() {
  num asNum = 1;
  Object asObject = 1;
  dynamic asDynamic = 1;
  int asInt1 = asNum; //# 01: compile-time error
  double asDouble1 = asNum; //# 02: compile-time error
  int asInt2 = asObject; //# 03: compile-time error
  double asDouble2 = asObject; //# 04: compile-time error
  String asString1 = asObject; //# 05: compile-time error
  int asInt3 = asDynamic; //# 06: ok
}
