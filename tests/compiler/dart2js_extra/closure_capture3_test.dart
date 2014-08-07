// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Closure {
  var x;
  Closure(val) : this.x = val;

  foo() {
    return () {
      return x;
    };
  }

  bar() {
    return () {
      return toto();
    };
  }

  toto() {
    return x + 1;
  }

  nestedClosure() {
    var f = () { return x; };
    return () { return f() + 2; };
  }
}

main() {
  var c = new Closure(499);
  var f = c.foo();
  Expect.equals(499, f());
  Expect.equals(500, c.bar()());
  Expect.equals(501, c.nestedClosure()());
}
