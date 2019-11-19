// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Testing that, when compiled to JS, Function.apply works correctly for
// functions with that will be invoked directly vs using .apply().

class A {
  foo([a = 10, b = 20, c = 30, d = 40, e = 50]) => "$a $b $c $d $e";
}

main() {
  var a = new A();
  var clos = a.foo;
  Expect.equals(Function.apply(clos, []), "10 20 30 40 50");
  Expect.equals(Function.apply(clos, [11]), "11 20 30 40 50");
  Expect.equals(Function.apply(clos, [11, 21]), "11 21 30 40 50");
  Expect.equals(Function.apply(clos, [11, 21, 31]), "11 21 31 40 50");
  Expect.equals(Function.apply(clos, [11, 21, 31, 41]), "11 21 31 41 50");
  Expect.equals(Function.apply(clos, [11, 21, 31, 41, 51]), "11 21 31 41 51");
}
