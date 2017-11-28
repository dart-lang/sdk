// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that implicit setters do a runtime type check.

import "package:expect/expect.dart";

class A {
  C c;
}

class B extends A {}

class C {}

var array = <dynamic>[new B()];

main() {
  array[0].c = new C();
  Expect.throwsTypeError(() => array[0].c = new B());
}
