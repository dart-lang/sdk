// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for bound closures.

import 'package:expect/expect.dart';

typedef Foo<T>(T t);

class Class<T> {
  foo(Foo<T> o) => o is Foo<T>;
}

bar(int i) {}

baz<T>(Foo<T> o) => o is Foo<T>;

void main() {
  dynamic f = new Class<int>().foo;
  Expect.isTrue(f(bar));
  Expect.isTrue(f is Foo<Foo<int>>);
  Expect.isFalse(f is Foo<int>);
  Expect.isFalse(f is Foo<Object>);
  Expect.throwsTypeError(() => f(f));
  Expect.throwsTypeError(() => f(42));

  Foo<Foo<int>> bazInt = baz; // implicit instantiation baz<int>
  f = bazInt;
  Expect.isTrue(f(bar));
  Expect.isFalse(f is Foo<int>);
  Expect.throwsTypeError(() => f(f));
  Expect.throwsTypeError(() => f(42));
}
