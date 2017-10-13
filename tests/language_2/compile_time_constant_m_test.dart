// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A();
  foo([x = const A()]) => x;
}

const x = const A();

foo([x = const A()]) => x;

main() {
  Expect.identical(x, foo());
  Expect.identical(x, x.foo());
}
