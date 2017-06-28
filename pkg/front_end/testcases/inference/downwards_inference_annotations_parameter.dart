// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Foo {
  const Foo(List<String> l);
}

void f(@Foo(/*@typeArgs=String*/ const []) x) {}

class C {
  void m(@Foo(/*@typeArgs=String*/ const []) /*@topType=dynamic*/ x) {}
}

main() {}
