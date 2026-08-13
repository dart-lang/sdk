// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo<T> {
  late T a;
  late final T b;
}

void main() {
  Foo<num> foo = Foo<num>();
  foo.a = 0;
  foo.b = 1;
  Expect.equals(0, foo.a);
  Expect.equals(1, foo.b);
  foo.a = 1.618;
  Expect.equals(1.618, foo.a);

  Foo<num> bar = Foo<int>();
  bar.a = 2;
  bar.b = 3;
  Expect.equals(2, bar.a);
  Expect.equals(3, bar.b);

  Expect.throws(() {
    bar.a = 3.14;
  });
}
