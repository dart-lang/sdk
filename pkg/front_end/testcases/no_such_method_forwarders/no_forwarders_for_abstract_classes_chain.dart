// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the noSuchMethod forwarders aren't generated for the
// abstract classes that have user-defined noSuchMethod, but rather in their
// top-most concrete descendants.  The immediate abstract children should not
// receive the forwarders.

abstract class A {
  noSuchMethod(i) => null;

  // The forwarder for [foo] shouldn't be generated here.
  void foo();
}

abstract class B extends A {
  // [B] shouldn't receive a forwarder.
}

class C extends B {
  // The forwarder for [foo] should be generated here.
}

class D extends C {
  // [D] shouldn't receiver a forwarder.
}

main() {}
