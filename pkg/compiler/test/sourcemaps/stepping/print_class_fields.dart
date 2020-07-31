// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*Debugger:stepOver*/
main() {
  /*bl*/
  Foo foo = new /*s:1*/ Foo(1, 2);
  /*s:2*/ print(foo.x);
  /*s:3*/ print(foo.y);
  /*s:4*/ print(foo.z);

  foo = new /*s:5*/ Foo.named();
  /*s:6*/ print(foo.x);
  /*s:7*/ print(foo.y);
  /*s:8*/ print(foo.z);
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
