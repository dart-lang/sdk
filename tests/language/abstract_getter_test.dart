// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test to ensure that an abstract getter is not mistaken for a field.

class Foo {
  // Intentionally abstract:
  get i; // //# 01: static type warning
}

class Bar {}

noMethod(e) => e is NoSuchMethodError;

checkIt(f) {
  Expect.throws(() { f.i = 'hi'; }, noMethod); // //# 01: continued
  Expect.throws(() { print(f.i); }, noMethod); // //# 01: continued
  Expect.throws(() { print(f.i()); }, noMethod); // //# 01: continued
}

main() {
  checkIt(new Foo());
  checkIt(new Bar());
}
