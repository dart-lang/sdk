// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the noSuchMethod forwarders aren't generated for the
// abstract classes that have user-defined noSuchMethod, but rather in their
// concrete descendants.

abstract class A {
  noSuchMethod(i) => null;

  // The forwarder for [foo] shouldn't be generated here.
  void foo();
}

class B extends A {
  // The forwarder for [foo] should be generated here.
}

main() {}
