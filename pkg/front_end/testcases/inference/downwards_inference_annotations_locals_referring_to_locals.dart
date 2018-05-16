// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Foo {
  const Foo(dynamic l);
}

void test() {
  const /*@type=int*/ x = 0;

  @Foo(/*@typeArgs=int*/ const [x])
  var /*@type=dynamic*/ y;

  @Foo(/*@typeArgs=int*/ const [x])
  void bar() {}

  void baz(@Foo(/*@typeArgs=int*/ const [x]) dynamic formal) {}
}

main() {}
