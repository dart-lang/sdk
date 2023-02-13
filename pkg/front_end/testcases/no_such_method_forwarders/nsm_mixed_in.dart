// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the noSuchMethod forwarder is generated in cases when
// the user-defined noSuchMethod is mixed in to a class with abstract methods.

class A {
  dynamic noSuchMethod(Invocation i) {
    return null;
  }
}

class B extends Object with A {
  void foo();
}

main() {}
