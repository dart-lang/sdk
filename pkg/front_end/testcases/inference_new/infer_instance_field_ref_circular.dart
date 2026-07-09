// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

// In the code below, there is a circularity between A.b and x.

class A {
  var b = () => x;
  var c = () => x;
}

var a = new A();
var x = () => a.b;
var y = () => a.c;

main() {}
