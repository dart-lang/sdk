// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void test() {
  var /*@type=int*/ i = 0;
  for (i++; i /*@target=num::<*/ < 10; i++) {}
  for (++i; i /*@target=num::<*/ < 10; i++) {}
  for (i--; i /*@target=num::>=*/ >= 0; i--) {}
  for (--i; i /*@target=num::>=*/ >= 0; i--) {}
}

main() {}
