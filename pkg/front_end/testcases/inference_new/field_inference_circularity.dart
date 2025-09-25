// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

// A.x depends on B.x which depends on A.x, so no type is inferred.  But types
// can be inferred for A.y and B.y.

class A {
  var x = () => new B().x;
  var y = () => new B().x;
}

class B extends A {
  var x;
  var y;
}

main() {}
