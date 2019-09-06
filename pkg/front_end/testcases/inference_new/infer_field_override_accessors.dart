// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  A get x;
  void set x(B value);

  B get y;
  void set y(A value);
}

abstract class B extends A {}

class C extends B {
  var x;
  var y;
}

main() {}
