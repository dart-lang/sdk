// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=dynamic*/ x = null;
var /*@topType=int*/ y = 3;

class A {
  static var /*@topType=dynamic*/ x = null;
  static var /*@topType=int*/ y = 3;

  var /*@topType=dynamic*/ x2 = null;
  var /*@topType=int*/ y2 = 3;
}

main() {
  x;
  y;
}
