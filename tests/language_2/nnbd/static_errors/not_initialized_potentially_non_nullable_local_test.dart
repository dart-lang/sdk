// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// It is an error if a potentially non-nullable local variable which has no
// initializer expression and is not marked `late` is used before it is
// definitely assigned.
// TODO(scheglov) Update once we implement definite assignment analysis.

void main() {
  int v; //# 01: compile-time error
  int v = 0; //# 02: ok
  late int v; //# 03: ok
  late int v = 0; //# 04: ok
  int? v; //# 05: ok
  int? v = 0; //# 06: ok

}

f<T>(T a) {
  T v; //# 07: compile-time error
  T v = a; //# 08: ok
  late T v; //# 09: ok
  late T v = a; //# 10: ok
  T? v; //# 11: ok
  T? v = a; //# 12: ok
}
