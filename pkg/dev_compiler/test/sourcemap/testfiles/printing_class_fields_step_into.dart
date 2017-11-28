// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*nb*/
main() {
  /*bl*/
  Foo foo = new /*bc:1*/ Foo(1, 2);
  /*bc:5*/ print(foo.x);
  /*bc:6*/ print(foo.y);
  /*bc:7*/ print(foo.z);
}

class Foo {
  var x, y, z;

  Foo(a, b)
      : this.x /*bc:2*/ = a,
        this.y /*bc:3*/ = b {
    z = a /*bc:4*/ + b;
  }
}
