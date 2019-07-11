// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C {
  static m({int a: 0}) {}
}

void test() {
  C.m(a: 1, a: 2, a: 3);
}

main() {}
