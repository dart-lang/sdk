// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that a noSuchMethod forwarder is generated in classes that
// inherit a user-defined noSuchMethod from their superclass and have not
// implemented abstract methods from their interfaces.

class A {
  dynamic noSuchMethod(Invocation i) {
    return null;
  }
}

abstract class I {
  void foo();
}

class B extends A implements I {}

main() {}
