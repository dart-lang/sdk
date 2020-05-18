// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void test() {
  var /*@ type=int* */ i = 0;
  for (i /*@target=num.+*/ ++;
      i /*@target=num.<*/ < 10;
      i /*@target=num.+*/ ++) {}
  for (/*@target=num.+*/ ++i;
      i /*@target=num.<*/ < 10;
      i /*@target=num.+*/ ++) {}
  for (i /*@target=num.-*/ --;
      i /*@target=num.>=*/ >= 0;
      i /*@target=num.-*/ --) {}
  for (/*@target=num.-*/ --i;
      i /*@target=num.>=*/ >= 0;
      i /*@target=num.-*/ --) {}
}

main() {}
