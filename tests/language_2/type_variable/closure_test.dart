// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C<T> {
  C.foo() {
    x = (a) => a is T;
  }
  C.bar() {
    x = (a) => a is! T;
  }
  C.baz() {
    x = (a) => a as T;
  }
  var x;
}

main() {
  Expect.isTrue(new C<int>.foo().x(1));
  Expect.isFalse(new C<int>.foo().x('1'));
  Expect.isFalse(new C<int>.bar().x(1));
  Expect.isTrue(new C<int>.bar().x('1'));
  Expect.equals(new C<int>.baz().x(1), 1);
  Expect.throws(() => new C<int>.baz().x('1'));
}
