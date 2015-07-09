// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that static const fields are accessible by reflection.
// Regression test for http://dartbug.com/23811.

@MirrorsUsed(targets: const [A])
import "dart:mirrors";
import "package:expect/expect.dart";

class A {
  static const ONE = 1;
}

main() {
  Expect.equals(1, reflectClass(A).getField(#ONE).reflectee);
}
