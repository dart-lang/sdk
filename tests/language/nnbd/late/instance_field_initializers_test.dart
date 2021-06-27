// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  testInitializerList();
  testInitializingFormals();
}

final List<int> history = [];

int log(int n) {
  history.add(n);
  return n;
}

class Foo {
  late int a;
  late final int b;
  late int c = log(-1);
  late final int d = log(-2);

  Foo.withC()
      : a = log(1),
        b = log(2),
        c = log(3);

  Foo.withoutC()
      : a = log(1),
        b = log(2);
}

void testInitializerList() {
  history.clear();

  var foo = Foo.withC();
  Expect.equals(1, foo.a);
  Expect.equals(2, foo.b);
  Expect.equals(3, foo.c);
  Expect.equals(-2, foo.d);

  foo.a = log(100);
  Expect.throws(() {
    foo.b = log(101);
  });
  foo.c = log(102);

  Expect.equals(100, foo.a);
  Expect.equals(2, foo.b);
  Expect.equals(102, foo.c);

  Expect.listEquals([1, 2, 3, -2, 100, 101, 102], history);

  history.clear();

  foo = Foo.withoutC();
  Expect.equals(1, foo.a);
  Expect.equals(2, foo.b);
  Expect.equals(-1, foo.c);
  Expect.equals(-2, foo.d);

  foo.a = log(100);
  Expect.throws(() {
    foo.b = log(101);
  });
  foo.c = log(102);

  Expect.equals(100, foo.a);
  Expect.equals(2, foo.b);
  Expect.equals(102, foo.c);

  Expect.listEquals([1, 2, -1, -2, 100, 101, 102], history);
}

class Bar {
  late int a;
  late final int b;
  late int c = log(-1);
  late final int d = log(-2);

  Bar.withC(this.a, this.b, this.c);

  Bar.withoutC(this.a, this.b);
}

void testInitializingFormals() {
  history.clear();

  var bar = Bar.withC(log(1), log(2), log(3));
  Expect.equals(1, bar.a);
  Expect.equals(2, bar.b);
  Expect.equals(3, bar.c);
  Expect.equals(-2, bar.d);

  bar.a = log(100);
  Expect.throws(() {
    bar.b = log(101);
  });
  bar.c = log(102);

  Expect.equals(100, bar.a);
  Expect.equals(2, bar.b);
  Expect.equals(102, bar.c);

  Expect.listEquals([1, 2, 3, -2, 100, 101, 102], history);

  history.clear();

  bar = Bar.withoutC(log(1), log(2));
  Expect.equals(1, bar.a);
  Expect.equals(2, bar.b);
  Expect.equals(-1, bar.c);
  Expect.equals(-2, bar.d);

  bar.a = log(100);
  Expect.throws(() {
    bar.b = log(101);
  });
  bar.c = log(102);

  Expect.equals(100, bar.a);
  Expect.equals(2, bar.b);
  Expect.equals(102, bar.c);

  Expect.listEquals([1, 2, -1, -2, 100, 101, 102], history);
}
