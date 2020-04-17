// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js's inferrer that used to not propagate
// types given to generative constructors in super constructor calls.

import "package:expect/expect.dart";

class A {
  final field;
  A.full(this.field);
}

class B extends A {
  // The following super call used to not be analyzed properly.
  B.full(field) : super.full(field);
}

main() {
  // Call [A.full] with an int to have the inferrer think [field] is
  // always an int.
  Expect.equals(84, new A.full(42).field + 42);
  Expect.throwsNoSuchMethodError(() => new B.full(null).field + 42,);
}
