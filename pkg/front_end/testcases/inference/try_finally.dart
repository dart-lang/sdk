// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void test(void f()) {
  try {
    var /*@type=int*/ x = 0;
    f();
  } finally {
    var /*@type=int*/ x = 0;
  }
}

main() {}
