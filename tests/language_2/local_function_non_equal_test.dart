// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

foo() => () => 42;
bar() {
  var c = () => 54;
  return c;
}

baz() {
  c() => 68;
  return c;
}

main() {
  var first = foo();
  var second = foo();
  Expect.isFalse(identical(first, second));
  Expect.notEquals(first, second);

  first = bar();
  second = bar();
  Expect.isFalse(identical(first, second));
  Expect.notEquals(first, second);

  first = baz();
  second = baz();
  Expect.isFalse(identical(first, second));
  Expect.notEquals(first, second);
}
