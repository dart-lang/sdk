// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var field;
  A.bar() : field = 1;
  A() : field = 2;
}

class Mixin {}

class B extends A with Mixin {}

main() {
  Expect.equals(2, new B().field);
  new B.bar(); /*@compile-error=unspecified*/
}
