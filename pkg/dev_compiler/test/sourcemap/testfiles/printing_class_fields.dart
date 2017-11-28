// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*Debugger:stepOver*/
main() {
  /*bl*/
  /*sl:1*/ Foo foo = new Foo(1, 2);
  /*sl:2*/ print(foo.x);
  /*sl:3*/ print(foo.y);
  /*sl:4*/ print(foo.z);

  /*sl:5*/ foo = new Foo.named();
  /*sl:6*/ print(foo.x);
  /*sl:7*/ print(foo.y);
  /*sl:8*/ print(foo.z);
}

class Foo {
  var x, y, z;

  Foo(a, b)
      : this.x = a,
        this.y = b {
    z = a + b;
  }

  Foo.named()
      : this.x = 42,
        this.y = 88 {
    z = 28;
  }
}
