// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error to use nullable types in unsound ways.
void main() {
  List? list;
  list..add(0); //# 00: compile-time error
  list?..add(0); //# 01: ok
  list..toString(); //# 02: ok
  list?..toString(); //# 03: ok
  list..last = 0; //# 04: compile-time error
  list?..last = 0; //# 05: ok
  list..[0] = 0; //# 06: compile-time error
  list?..[0] = 0; //# 07: ok

  // Note: the following look weird because they call a getter (or
  // getter-like operator) and discard the result, but they are
  // permitted by both the analyzer and the front end, so we should
  // test them.
  list..add; //# 08: compile-time error
  list?..add; //# 09: ok
  list..toString; //# 10: ok
  list?..toString; //# 11: ok
  list..last; //# 12: compile-time error
  list?..last; //# 13: ok
  list..runtimeType; //# 14: ok
  list?..runtimeType; //# 15: ok
  list..[0]; //# 16: compile-time error
  list?..[0]; //# 17: ok
}
