// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  foo() => 42;
}

class B implements A {
  noSuchMethod(im) => 84;
}

main() {
  var a = [new A(), new B()];
  var b = a[1];
  if (b is A) {
    // `b.foo()` will create a typed selector whose receiver type is a
    // subtype of `A`. Because not all subtypes of `A` implement
    // `foo`, dart2js must generate a `noSuchMethod` stub for `foo` in
    // the top Object class.
    Expect.equals(84, b.foo());
    return;
  }
  Expect.fail('Should not be here');
}
