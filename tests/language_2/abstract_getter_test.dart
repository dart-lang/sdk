// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test to ensure that an abstract getter is not mistaken for a field.

class Foo {
  // Intentionally abstract:
  get i; //# 01: compile-time error
}

class Bar {}

checkIt(f) {
  Expect.throwsNoSuchMethodError(() => f.i = 'hi'); // //# 01: continued
  Expect.throwsNoSuchMethodError(() => print(f.i)); // //# 01: continued
  Expect.throwsNoSuchMethodError(() => print(f.i())); // //# 01: continued
}

main() {
  checkIt(new Foo());
  checkIt(new Bar());
}
