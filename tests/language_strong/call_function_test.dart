// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

Object bar(Object x) {
  return x;
}

Function baz = bar;

dynamic dyn = bar;

class Foo {
  Object call(Object x) {
    return 'Foo$x';
  }
}

typedef Object FooType(Object x);
FooType foo = bar;

void main() {
  Expect.equals(42, bar.call(42));
  Expect.equals(42, baz.call(42));
  Expect.equals(42, foo.call(42));
  Expect.equals(42, dyn.call(42));
  Expect.equals(42, bar(42));
  Expect.equals(42, baz(42));
  Expect.equals(42, foo(42));
  Expect.equals(42, dyn(42));

  baz = new Foo();
  foo = new Foo();
  dyn = new Foo();
  Expect.equals('Foo42', baz.call(42));
  Expect.equals('Foo42', foo.call(42));
  Expect.equals('Foo42', dyn.call(42));
  Expect.equals('Foo42', baz(42));
  Expect.equals('Foo42', foo(42));
  Expect.equals('Foo42', dyn(42));
}
