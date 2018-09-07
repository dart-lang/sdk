// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void foo<X>(X i) {
  print(i);
}

class Foo {
  static foo<X>(X i) {
    print(i);
  }

  bar<X>(X i) {
    print(i);
  }
}

class Bar<X, Y> {}

main() {
  foo<String, String>("hello world");
  foo<String>("hello world");
  Foo.foo<int, int>(42);
  Foo.foo<int>(42);
  Foo f = new Foo();
  f.bar<double, double>(42.42);
  f.bar<double>(42.42);
  new Bar<String>();
  new Bar<String, String>();
}
