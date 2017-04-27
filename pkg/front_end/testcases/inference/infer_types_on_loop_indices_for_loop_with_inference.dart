// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test() {
  for (var /*@type=int*/ i = 0; /*@promotedType=none*/ i <
      10; /*@promotedType=none*/ i++) {
    int j = /*@promotedType=none*/ i + 1;
  }
}
