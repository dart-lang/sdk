// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to duplicate some `Object`
// methods to handle `noSuchMethod`.

import "package:expect/expect.dart";
import "compiler_annotations.dart";

abstract //# 01: static type warning
class Foo {
  noSuchMethod(im) => 42;
}

@DontInline()
returnFoo() {
  (() => 42)();
  return new Foo();
}

class Bar {
  operator ==(other) => false;
}

var a = [false, true, new Object(), new Bar()];

main() {
  if (a[0]) {
    // This `==` call will make the compiler create a selector with an
    // exact `TypeMask` of `Foo`. Since `Foo` is abstract, such a call
    // cannot happen, but we still used to generate a `==` method on
    // the `Object` class to handle `noSuchMethod`.
    print(returnFoo() == 42);
  } else {
    Expect.isFalse(a[2] == 42);
  }
}
