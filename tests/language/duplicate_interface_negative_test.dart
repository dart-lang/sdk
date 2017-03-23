// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fail because of cycles in super class relationship.

library duplicateInterfaceNegativeTest;

import "duplicate_interface_lib.dart" as alib;
import "duplicate_interface_lib.dart" show InterfA;

// Expect error since InterfA and alib.InterfA refer to the same interface.
class Foo implements InterfA, alib.InterfA { } //# compile-time error

main() {
  Expect.isTrue(new Foo() is InterfA);
  Expect.isTrue(new Foo() is alib.InterfA);
}
