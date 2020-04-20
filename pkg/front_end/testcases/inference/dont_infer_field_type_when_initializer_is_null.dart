// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var x = null;
var y = 3;

class A {
  static var x = null;
  static var y = 3;

  var x2 = null;
  var y2 = 3;
}

main() {
  x;
  y;
}
