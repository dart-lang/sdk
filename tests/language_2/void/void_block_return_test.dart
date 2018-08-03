// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing that a void block function is not allowed to `return e`
// where `e` is non-void.

void foo() {
  return 42; //# 00: compile-time error
}

main() {
  foo();
}
