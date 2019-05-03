// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<X> {
  const Foo();
  const Foo.bar();
  const Foo.baz();
}

main() {
  new Foo(); //# 01: ok
  new Foo.bar(); //# 02: ok
  new Foo.bar.baz(); //# 03: compile-time error
  new Foo<int>(); //# 04: ok
  new Foo<int>.bar(); //# 05: ok
  new Foo<int>.bar.baz(); //# 06: syntax error
  new Foo.bar<int>(); //# 07: compile-time error
  new Foo.bar<int>.baz(); //# 08: compile-time error
  new Foo.bar.baz<int>(); //# 09: syntax error

  const Foo(); //# 11: ok
  const Foo.bar(); //# 12: ok
  const Foo.bar.baz(); //# 13: compile-time error
  const Foo<int>(); //# 14: ok
  const Foo<int>.bar(); //# 15: ok
  const Foo<int>.bar.baz(); //# 16: syntax error
  const Foo.bar<int>(); //# 17: compile-time error
  const Foo.bar<int>.baz(); //# 18: compile-time error
  const Foo.bar.baz<int>(); //# 19: syntax error

  Foo(); //# 21: ok
  Foo.bar(); //# 22: ok
  Foo.bar.baz(); //# 23: compile-time error
  Foo<int>(); //# 24: ok
  Foo<int>.bar(); //# 25: ok
  Foo<int>.bar.baz(); //# 26: syntax error
  Foo.bar<int>(); //# 27: compile-time error
  Foo.bar<int>.baz(); //# 28: compile-time error
  Foo.bar.baz<int>(); //# 29: compile-time error
}
