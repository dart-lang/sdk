// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that a "factory provider" interface factory only
// provides the constructors declared in the interface.

interface Interface default FactoryProvider {
  Interface.some_name(var secret);
}

class SomeImplementation implements Interface {
  SomeImplementation() {}
}

class FactoryProvider {
  factory Interface.some_name() {
    return new SomeImplementation();
  }

  factory Interface.wrong_name() {
    return new SomeImplementation();
  }

  static testMain() {
    // We should not be able to find Interface1.wrong_name().
    new Interface.wrong_name();
  }
}

main() {
  FactoryProvider.testMain();
}
