// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fail because of cycles in super class relationship.

library duplicateInterfaceTest;

import 'package:expect/expect.dart';
import "duplicate_interface_lib.dart" as alib;

class InterfB {}

// Ok since InterfB and alib.InterfB are not the same interface
class Foo implements InterfB, alib.InterfB {}

main() {
  Expect.isTrue(new Foo() is InterfB);
  Expect.isTrue(new Foo() is alib.InterfB);
}
