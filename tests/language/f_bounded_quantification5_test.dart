// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for F-Bounded Quantification.

import "package:expect/expect.dart";

class A<T extends B<T>> {}

class B<T extends A<T>> {}

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

main() {
  bool got_type_error = false;
  try {
    // Getting "int" when calling toString() on the int type is not required.
    // However, we want to keep the original names for the most common core
    // types so we make sure to handle these specifically in the compiler.
    Expect.equals("A<B<int>>", new A<B<int>>().runtimeType.toString());
  } on TypeError catch (error) {
    got_type_error = true;
  }
  // Type error expected in checked mode only.
  Expect.isTrue(got_type_error == isCheckedMode());
}
