// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final field;
  const A() : field = 499;
}

const x = (((1 + 2)));
const y = (((((x)))));
const z = (((const A())));

main() {
  Expect.equals(3, x);
  Expect.equals(3, y);
  Expect.equals(499, z.field);
}
