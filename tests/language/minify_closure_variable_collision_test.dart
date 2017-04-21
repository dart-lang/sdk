// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js, that used to minify a captured
// variable's name to the same name as inherited Object methods.

var array = [new A()];

class A {
  operator ==(other) {
    return true;
  }
}

foo() {
  // Use lots of variables, to maximize the chance of collisions.
  var a = 42;
  var b = 42;
  var c = 42;
  var d = 42;
  var e = 42;
  var f = 42;
  var g = 42;
  var h = 42;
  var i = 42;
  var j = 42;
  var k = 42;
  var l = 42;
  var m = 42;
  var n = 42;
  array[0] = () {
    return a + b + c + d + e + f + g + h + i + j + k + l + m + n;
  };
}

main() {
  foo();
  if (array[0] == new A()) {
    throw 'Test failed';
  }
  if (array[0]() != 42 * 14) {
    throw 'Test failed';
  }
}
