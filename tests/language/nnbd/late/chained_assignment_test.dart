// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  int x = 0;

  int _y = 0;
  int get y => _y;
  void set y(int y) => _y = y;

  static late int z;
  late int w;
}

void main() {
  final foo = Foo();
  int a = 0;
  late int b;
  late int c;
  late int d;

  b = a = 1;
  Expect.equals(1, a);
  Expect.equals(1, b);

  a = b = 2;
  Expect.equals(2, a);
  Expect.equals(2, b);

  b = foo.x = 3;
  Expect.equals(3, foo.x);
  Expect.equals(3, b);

  foo.x = b = 4;
  Expect.equals(4, foo.x);
  Expect.equals(4, b);

  b = foo.y = 5;
  Expect.equals(5, foo.y);
  Expect.equals(5, b);

  foo.y = b = 6;
  Expect.equals(6, foo.y);
  Expect.equals(6, b);

  b = c = 7;
  Expect.equals(7, b);
  Expect.equals(7, c);

  d = b = 8;
  Expect.equals(8, b);
  Expect.equals(8, d);

  Foo.z = a = 9;
  Expect.equals(9, a);
  Expect.equals(9, Foo.z);

  a = Foo.z = 10;
  Expect.equals(10, a);
  Expect.equals(10, Foo.z);

  Foo.z = foo.x = 11;
  Expect.equals(11, foo.x);
  Expect.equals(11, Foo.z);

  foo.x = Foo.z = 12;
  Expect.equals(12, foo.x);
  Expect.equals(12, Foo.z);

  Foo.z = foo.y = 13;
  Expect.equals(13, foo.y);
  Expect.equals(13, Foo.z);

  foo.y = Foo.z = 14;
  Expect.equals(14, foo.y);
  Expect.equals(14, Foo.z);

  foo.w = a = 15;
  Expect.equals(15, a);
  Expect.equals(15, foo.w);

  a = foo.w = 16;
  Expect.equals(16, a);
  Expect.equals(16, foo.w);

  foo.w = foo.x = 17;
  Expect.equals(17, foo.x);
  Expect.equals(17, foo.w);

  foo.x = foo.w = 18;
  Expect.equals(18, foo.x);
  Expect.equals(18, foo.w);

  foo.w = foo.y = 19;
  Expect.equals(19, foo.y);
  Expect.equals(19, foo.w);

  foo.y = foo.w = 20;
  Expect.equals(20, foo.y);
  Expect.equals(20, foo.w);
}
