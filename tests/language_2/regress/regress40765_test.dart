// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Something {
  final int x;
  Something({this.x});
}

abstract class Base {
  Something get x;
}

class Child1 extends Base {
  final Something x;
  Child1({this.x});
}

class Child2 extends Base {
  final int y;
  final Something x;
  Child2({this.x, this.y});
}

@pragma('vm:never-inline')
int foo(int k, Base x) {
  var y = 0;
  for (var i = 0; i < k; i++) {
    x as Child1;
    // Next line will be hoisted out as x.{Child1::x}.{Something::x}
    // and at foo(0, Child2(..., y: 24)) will end up executing as
    // x.{Child1::x} -> will load Child2::y (24) and then segfault.
    y = x.x.x;
  }
  return y;
}

void main() {
  print(foo(1, Child1(x: Something(x: 1))));
  print(foo(1, Child1(x: Something(x: 2))));
  print(foo(0, Child2(x: Something(x: 42), y: 24)));
}
