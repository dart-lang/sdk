// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  operator -() => this;
  toString() => "5";
  abs() => "correct";
}

// This triggered a bug in Dart2Js: the speculative type optimization assigned
// type "number" to 'a' and then to '-a'. In the bailout version the type for
// 'a' was removed, but the type for '-a' was kept.
foo(a) => -(-a);

main() {
  Expect.equals("correct", foo(new A()).abs());
}
