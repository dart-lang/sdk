// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var string = '';

append(x) {
  string += x;
  return x;
}

class A {
  var x = append('x');
  var y;
  var z;

  // Should append y but not yet x.
  A() : this.foo(append('y'));

  // Append x and z.
  A.foo(this.y) : z = append('z');
}

class B extends A {
  var w;

  // Call the redirecting constructor using super.
  B()
      : w = append('w'),
        super();
}

main() {
  string = '';
  new A();
  Expect.equals('yxz', string);

  string = '';
  new B();
  Expect.equals('wyxz', string);
}
