// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Foo {
  const Foo(List<String> l);
}

abstract class Bar {
  @Foo(/*@ typeArgs=String* */ const [])
  Bar();

  @Foo(/*@ typeArgs=String* */ const [])
  var x;

  @Foo(/*@ typeArgs=String* */ const [])
  void f();
}

main() {}
