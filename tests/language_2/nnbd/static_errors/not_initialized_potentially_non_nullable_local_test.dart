// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// It is an error if a potentially non-nullable local variable which has no
// initializer expression and is not marked `late` is used before it is
// definitely assigned.
// TODO(scheglov) Update once we implement definite assignment analysis.

void main() {
  int v; v; //# 01: compile-time error
  int v; //# 02: ok
  int v = 0; //# 03: ok
  late int v; //# 04: ok
  late int v = 0; //# 05: ok
  int? v; //# 06: ok
  int? v = 0; //# 07: ok

}

f<T>(T a) {
  T v; v; //# 08: compile-time error
  T v = a; //# 09: ok
  late T v; //# 10: ok
  late T v = a; //# 11: ok
  T? v; //# 12: ok
  T? v = a; //# 13: ok
}
