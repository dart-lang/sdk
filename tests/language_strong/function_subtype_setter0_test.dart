// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for implicit setters.

import 'package:expect/expect.dart';

typedef void Foo();

class A<T> {}

class C {
  Foo foo;
  A<int> bar;
}

class D {
  Foo foo;
  A<int> bar;
}

test(var c) {
  bool inCheckedMode = false;
  try {
    var x = 42;
    String a = x;
  } catch (e) {
    inCheckedMode = true;
  }
  if (inCheckedMode) {
    Expect.throws(() => c.foo = 1, (e) => true);
  }
  c.foo = () {};
}

void main() {
  test(new C());
  test(new D());
}
