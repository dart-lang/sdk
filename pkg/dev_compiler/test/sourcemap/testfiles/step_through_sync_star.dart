// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  /* bl */
  /*sl:1*/ var iterator = naturalsTo(2);
  for (var /*bc:3*/ /*bc:8*/ /*bc:12*/ i in /*bc:2*/ iterator) {
    /*bc:7*/ /*bc:11*/ print(i);
  }
}

Iterable<int> naturalsTo(int n) sync* {
  /*sl:4*/ var k = 0;
  /*sl:5*/ /*sl:9*/ /*sl:13*/ while (k < n) {
    /*nbb:0:6*/ /*sl:6*/ /*sl:10*/ yield ++k;
  }
}
