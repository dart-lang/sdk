// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int i = 5;

int test1() {
  return i ++ (i);
}

int test2() {
  return (i) ++ (i);
}

main() {
  test1();
  // Don't call test2, as error recovery has put a runtime error in there.
}
