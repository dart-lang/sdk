// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that the abstract setter is not shadowed by a method with the
// same name when generating the noSuchMethod forwarder for the setter.

class A {
  // This method is not abstract.
  void foo(int x) {}

  void set foo(int x);

  dynamic noSuchMethod(Invocation i) => null;
}

main() {}
