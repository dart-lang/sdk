// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class Foo {
  const Foo(dynamic l);
}

void test() {
  const x = 0;

  @Foo(const [x])
  var y;

  @Foo(const [x])
  void bar() {}

  void baz(@Foo(const [x]) dynamic formal) {}
}

main() {}
