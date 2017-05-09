// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

const /*@topType=int*/ x1 = 1;
final /*@topType=int*/ x2 = 1;
final /*@topType=int*/ y1 = x1;
final /*@topType=int*/ y2 = x2;

foo() {
  int i;
  i = y1;
  i = y2;
}

main() {
  foo();
}
