// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the generated noSuchMethod forwarder for a
// non-implemented abstract method has all the references to the type variables
// in its signature replaced with the appropriate types.

abstract class I<T> {
  T foo();
}

class M {
  dynamic noSuchMethod(Invocation i) {
    return null;
  }
}

class A extends Object with M implements I<int> {}

main() {}
