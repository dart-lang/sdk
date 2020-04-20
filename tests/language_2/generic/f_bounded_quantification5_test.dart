// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for F-Bounded Quantification.

import "package:expect/expect.dart";

@pragma("vm:entry-point")
class A<T extends B<dynamic>> {}

@pragma("vm:entry-point")
class B<T extends Object> {}

main() {
  // Getting "int" when calling toString() on the int type is not required.
  // However, we want to keep the original names for the most common core
  // types so we make sure to handle these specifically in the compiler.
  Expect.equals("A<B<int>>", new A<B<int>>().runtimeType.toString());
}
