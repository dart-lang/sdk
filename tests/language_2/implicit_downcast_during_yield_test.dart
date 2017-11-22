// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

Iterable<B> f(A a) sync* {
  yield a;
}

void main() {
  A a = new B();
  for (var x in f(a)) {} // No error
  a = new A();
  var iterator = f(a).iterator;
  Expect.throwsTypeError(() {
    iterator.moveNext();
  });
}
