// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that a "default implementation" interface factory checks the
// arity of its declared constructor arguments

interface Interface default DefaultImplementation {
  Interface(int x, int y);
}

class DefaultImplementation implements Interface {
  DefaultImplementation() {}

  static testMain() {
    // We should not be able to find the nullary Interface constructor.
    new Interface();
  }
}

main() {
  DefaultImplementation.testMain();
}
