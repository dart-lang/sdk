// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

void main() {
  Object o = <A>[];
  for (var x in o) {} // No error
  for (B x in o) {} // No error
  B y;
  for (y in o) {} // No error
  o = new Object();
  Expect.throwsTypeError(() {
    for (var x in o) {}
  });
  Expect.throwsTypeError(() {
    for (B x in o) {}
  });
  Expect.throwsTypeError(() {
    for (y in o) {}
  });
}
