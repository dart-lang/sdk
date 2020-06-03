// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  test();
}

// Testing that a block bodied function may not return non-void non-top values
void test() {
  return /*@compile-error=unspecified*/ 3;
}
