// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that a "default implementation" interface factory only
// provides the constructors declared in the interface.

interface Interface default DefaultImplementation {
  Interface.some_name();
}

class DefaultImplementation implements Interface {
  DefaultImplementation.some_name() {}
  DefaultImplementation.wrong_name() {}

  static testMain() {
    // We should not be able to find Interface.wrong_name().
    new Interface.wrong_name();
  }
}

main() {
  DefaultImplementation.testMain();
}
