// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  bool isNaN() => false;
}

main() {
  Expect.isTrue(foo(double.NAN));
  Expect.isFalse(foo(new A()));
  Expect.throws(() => foo('bar'), (e) => e is NoSuchMethodError);
}

foo(a) => a.isNaN();
