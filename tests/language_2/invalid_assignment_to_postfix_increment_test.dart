// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void f(int x, int y) {
  x++ = y; //# 01: compile-time error
  x++ += y; //# 02: compile-time error
  x++ ??= y; //# 03: compile-time error
}

main() {
  f(1, 2);
}
