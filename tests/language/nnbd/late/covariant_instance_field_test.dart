// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  covariant late num a;
  covariant late final num b;
}

class Bar extends Foo {
  @override
  late int a;

  @override
  late final int b;
}

void main() {
  Foo foo = Foo();
  foo.a = 0;
  foo.b = 1;
  Expect.equals(0, foo.a);
  Expect.equals(1, foo.b);
  foo.a = 1.618;
  Expect.equals(1.618, foo.a);

  Foo bar = Bar();
  bar.a = 2;
  bar.b = 3;
  Expect.equals(2, bar.a);
  Expect.equals(3, bar.b);

  Expect.throws(() {
    bar.a = 3.14 as dynamic;
  });
}
