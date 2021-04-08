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
  Expect.equals(a, 1);
  Expect.equals(b, 1);

  a = b = 2;
  Expect.equals(a, 2);
  Expect.equals(b, 2);

  b = foo.x = 3;
  Expect.equals(foo.x, 3);
  Expect.equals(b, 3);

  foo.x = b = 4;
  Expect.equals(foo.x, 4);
  Expect.equals(b, 4);

  b = foo.y = 5;
  Expect.equals(foo.y, 5);
  Expect.equals(b, 5);

  foo.y = b = 6;
  Expect.equals(foo.y, 6);
  Expect.equals(b, 6);

  b = c = 7;
  Expect.equals(b, 7);
  Expect.equals(c, 7);

  d = b = 8;
  Expect.equals(b, 8);
  Expect.equals(d, 8);

  Foo.z = a = 9;
  Expect.equals(a, 9);
  Expect.equals(Foo.z, 9);

  a = Foo.z = 10;
  Expect.equals(a, 10);
  Expect.equals(Foo.z, 10);

  Foo.z = foo.x = 11;
  Expect.equals(foo.x, 11);
  Expect.equals(Foo.z, 11);

  foo.x = Foo.z = 12;
  Expect.equals(foo.x, 12);
  Expect.equals(Foo.z, 12);

  Foo.z = foo.y = 13;
  Expect.equals(foo.y, 13);
  Expect.equals(Foo.z, 13);

  foo.y = Foo.z = 14;
  Expect.equals(foo.y, 14);
  Expect.equals(Foo.z, 14);

  foo.w = a = 15;
  Expect.equals(a, 15);
  Expect.equals(foo.w, 15);

  a = foo.w = 16;
  Expect.equals(a, 16);
  Expect.equals(foo.w, 16);

  foo.w = foo.x = 17;
  Expect.equals(foo.x, 17);
  Expect.equals(foo.w, 17);

  foo.x = foo.w = 18;
  Expect.equals(foo.x, 18);
  Expect.equals(foo.w, 18);

  foo.w = foo.y = 19;
  Expect.equals(foo.y, 19);
  Expect.equals(foo.w, 19);

  foo.y = foo.w = 20;
  Expect.equals(foo.y, 20);
  Expect.equals(foo.w, 20);
}
