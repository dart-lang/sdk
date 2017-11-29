// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

void main() {
  List<A> listOfA = <A>[new B()];
  Object o = listOfA;
  for (B x in o) {} // No error
  for (B x in listOfA) {} // No error
  B y;
  for (y in o) {} // No error
  for (y in listOfA) {} // No error
  listOfA[0] = new A();
  Expect.throwsTypeError(() {
    for (B x in o) {}
  });
  Expect.throwsTypeError(() {
    for (B x in listOfA) {}
  });
  Expect.throwsTypeError(() {
    for (y in o) {}
  });
  Expect.throwsTypeError(() {
    for (y in listOfA) {}
  });
}
