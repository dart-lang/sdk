// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that ensures that fields can be accessed dynamically.

import "package:expect/expect.dart";

class A extends C {
  var a;
  var b;
}

class C {
  foo() {


  }
  bar() {


  }
}

main() {
  var a = new A();
  a.a = 1;
  a.b = a;


}
