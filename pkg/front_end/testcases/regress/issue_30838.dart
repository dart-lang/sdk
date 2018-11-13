// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Foo<S> = S Function<T>(T x);
int foo<T>(T x) => 3;
Foo<int> bar() => foo;
void test1() {
  bar()<String>("hello");
}

class A {
  Foo<int> f;
  void test() {
    f<String>("hello");
  }
}

main() {}
