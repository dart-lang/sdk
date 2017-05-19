// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

void add(int x) {}
add2(int y) {}
main() {
  Future<int> f;
  var /*@type=Future<void>*/ a =
      f. /*@typeArgs=void*/ /*@target=Future::then*/ then(add);
  var /*@type=Future<dynamic>*/ b =
      f. /*@typeArgs=dynamic*/ /*@target=Future::then*/ then(add2);
}
