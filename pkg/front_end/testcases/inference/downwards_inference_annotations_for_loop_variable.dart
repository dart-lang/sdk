// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Foo {
  const Foo(List<String> l);
}

void test() {
  for (@Foo(/*@typeArgs=String*/ const []) int i = 0;
       i /*@target=num::<*/< 1; i++) {}
  for (@Foo(/*@typeArgs=String*/ const []) int i in /*@typeArgs=int*/[0]) {}
}

main() {}
