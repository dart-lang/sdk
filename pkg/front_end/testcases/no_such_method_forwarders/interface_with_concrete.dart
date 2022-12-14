// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This method checks that the noSuchMethod forwarder is generated in cases when
// the class of the implemented interface has concrete methods.

class A {
  dynamic noSuchMethod(Invocation i) {
    return null;
  }
}

class I {
  // This method is concrete.
  void foo() {}
}

class B extends A implements I {}

main() {}
