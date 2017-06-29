// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => null;

void test() {
  do {
    var /*@type=int*/ x = 0;
  } while (/*@typeArgs=bool*/ f());
}

main() {}
