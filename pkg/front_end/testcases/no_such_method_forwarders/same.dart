// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that a noSuchMethod forwarder is generated in the case when
// the user-defined noSuchMethod and the abstract method are both defined in the
// same class.

class A {
  dynamic noSuchMethod(Invocation i) {
    return null;
  }

  void foo();
}

main() {}
