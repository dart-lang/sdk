// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class X {
  final x;
  const X(this.x);
}

void main() {
  print(const X(1 << -1).x);  //# 01: compile-time error
  print(const X(1 >> -1).x);  //# 02: compile-time error
  print(const X(1 % 0).x);    //# 03: compile-time error
  print(const X(1 ~/ 0).x);   //# 04: compile-time error
}
