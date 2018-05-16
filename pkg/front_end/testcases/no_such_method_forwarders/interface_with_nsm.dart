// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that if an interface have a user-defined noSuchMethod, its
// implementations that have their own user-defined noSuchMethods still receive
// the noSuchMethod forwarders for each not implemented method from the
// interface.

class I {
  dynamic noSuchMethod(Invocation i) => null;

  // This should be a noSuchMethod forwarder, because [I] has a user-defined
  // [noSuchMethod].
  void foo();
}

class M {
  dynamic noSuchMethod(Invocation i) => null;
}

class A extends Object with M implements I {}

class B extends Object with M implements I {}

main() {}
