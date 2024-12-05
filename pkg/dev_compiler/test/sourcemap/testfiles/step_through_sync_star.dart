// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  /* bl */
  /*sl:1*/ var iterator = naturalsTo(2);
  for (var /*sl:2*/ /*sl:4*/ i in iterator) {
    /*sl:3*/ /*sl:5*/ print(i);
  }
  /*s:6*/
}

Iterable<int> naturalsTo(int n) sync* {
  var k = 0;
  while (k < n) {
    yield ++k;
  }
}
