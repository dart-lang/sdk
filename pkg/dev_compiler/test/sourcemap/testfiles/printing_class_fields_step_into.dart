// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*nb*/
void main() {
  /*bl*/
  var foo = /*sl:1*/ Foo(1, 2);
  /*s:5*/ print(foo.x);
  /*s:6*/ print(foo.y);
  /*s:7*/ print(foo.z);
}

class Foo {
  int x, y, z;

  Foo(int a, int b)
      : this. /*sl:2*/ x = a, // `s:2` fails, DDK is missing hover info
        this. /*sl:3*/ y = b {
    // `s:3` fails, DDK is missing hover info
    z = a /*sl:4*/ + b;
  }
}
